import SwiftUI

// Core loop: listen demo → record → recognize → score → feedback → next.
// Backed by SpeechRecorder (AVAudioEngine + SFSpeechRecognizer, on-device)
// and PronunciationScorer (word-level Levenshtein).

struct PracticeScreen: View {
    let scene: SpeakScene
    let tier: SpeakSceneTier      // which difficulty bucket the user picked
    let filteredIndexes: [Int]?
    // 对话对练:非 nil 时你演该声线方("chris"=男声句 / "rosie"=女声句)。
    // 对方的句子自动播音频并轮转;你的句子照常录音 + SOE 评分。nil = 普通跟读。
    var drillUserVoice: String? = nil
    @Binding var path: NavigationPath

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var recorder = SpeechRecorder()
    @StateObject private var speaker = SpeechSpeaker()

    @State private var index: Int = 0
    @State private var lastResult: ScoreResult? = nil
    @State private var scoring = false             // SOE 异步评测进行中,防 timeout 与 .finished 重复触发
    @State private var lastError: String? = nil   // recorder failure reason, surfaced inline
    @State private var capturedSamples: [Float] = []
    @State private var sessionWeakAbsolute: Set<Int> = []   // absolute scene indexes flagged during this session
    @State private var permissionChecked = false
    @State private var showPermissionAlert = false
    @State private var recordStartedAt: Date? = nil   // 录音走秒(micButton 计时器)
    @State private var recordSession = 0              // 录音会话号:防旧 auto-stop 误停新录音
    @State private var maskedOn = false               // 对练②:遮住你的台词,凭中文提示盲说

    // 学习数据 S1:逐句累积真实 SOE 分,session 结束时经 store.logSession 落盘。
    // 按绝对句索引存,同句重录覆盖取最后一次;词匹配回落句不进这里(假分红线)。
    @State private var sessionStartedAt = Date()
    @State private var soeByIndex: [Int: (overall: Int, soe: SOEDetail)] = [:]

    // MARK: - 对练(drill)

    private var isDrill: Bool { drillUserVoice != nil }

    private func isUserTurn(_ s: SceneSentence) -> Bool {
        guard let uv = drillUserVoice else { return true }
        return (s.voice == "chris") == (uv == "chris")
    }

    // 进入新句时驱动轮次:对方句 → 自动播音频(.listening),播完/超时自动 advance。
    private func stepTurn() {
        guard isDrill, uiPhase == .idle,
              let s = sentences[safe: index], !isUserTurn(s) else { return }
        uiPhase = .listening
        speaker.speak(s, voice: s.preferredVoice)
        // 守护:音频缺失/播放失败也不卡死(按词数估个上限,锚定当前句防误跳)。
        let cap = min(12.0, max(3.0, Double(s.words.count) * 0.6 + 2.0))
        let anchor = index
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(cap))
            if uiPhase == .listening && index == anchor { advance() }
        }
    }

    enum UIPhase: Equatable { case idle, recording, analyzing, feedback, listening, denied }
    @State private var uiPhase: UIPhase = .idle

    // MARK: - Derived

    private var sentences: [SceneSentence] {
        if let idxs = filteredIndexes {
            return idxs.compactMap { tier.sentences[safe: $0] }
        }
        return tier.sentences
    }

    private var absoluteIndexForCurrent: Int {
        filteredIndexes?[safe: index] ?? index
    }

    // MARK: - Body

    var body: some View {
        let p = theme.palette
        let sentence = sentences[safe: index]
        VStack(spacing: 0) {
            topBar
            if let s = sentence {
                sentenceBlock(s)
            }
            Spacer(minLength: 0)
            controls
        }
        .background(p.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if !permissionChecked {
                permissionChecked = true
                let ok = await recorder.requestPermissions()
                if !ok { uiPhase = .denied; showPermissionAlert = true }
                else { stepTurn() }   // 对练:首句若是对方句,自动开播
            }
        }
        .onChange(of: recorder.phase) { _, newPhase in
            handleRecorderPhase(newPhase)
        }
        // 对练:对方句音频播完 → 停顿半拍自动轮转到下一句。
        .onChange(of: speaker.isSpeaking) { _, speaking in
            guard isDrill, !speaking, uiPhase == .listening else { return }
            let anchor = index
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(550))
                if uiPhase == .listening && index == anchor { advance() }
            }
        }
        .alert("需要麦克风和语音识别权限",
               isPresented: $showPermissionAlert) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("打开「设置」→「原版娃口语」→ 允许麦克风和语音识别，就能开始跟读。")
        }
        .onDisappear {
            recorder.stop()
            // Fully release the audio session when we leave the screen.
            // While the screen is active we keep the session alive
            // between individual recordings to avoid a deactivate /
            // reactivate race in iOS.
            recorder.deactivateSession()
            speaker.stop()
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        let p = theme.palette
        let progress = Double(index + 1) / Double(max(1, sentences.count))
        return HStack(spacing: 14) {
            Button {
                Haptics.tap()
                recorder.stop()
                speaker.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(p.inkSoft)
            }
            .frame(width: 32, height: 32)
            ProgressView(value: progress)
                .tint(p.accent)
                .background(p.surfaceAlt)
                .clipShape(Capsule())
            Text("\(index + 1)/\(sentences.count)")
                .font(AppFont.enSans(size: 13, weight: .semibold))
                .foregroundStyle(p.inkSoft)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Sentence block

    private func sentenceBlock(_ s: SceneSentence) -> some View {
        let p = theme.palette
        let showFeedback = uiPhase == .feedback && lastResult != nil
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Chip(text: chipLabel, tone: .neutral)
                        Spacer()
                        if isDrill { maskToggle }
                    }
                    .padding(.bottom, 24)
                    Text("中文提示")
                        .font(AppFont.zh(size: 13))
                        .foregroundStyle(p.inkSoft)
                        .padding(.bottom, 10)
                    Text(s.zh)
                        .font(AppFont.zh(size: 18, weight: .medium))
                        .foregroundStyle(p.ink)
                        .padding(.bottom, 28)
                    Group {
                        // 对练②盲说:你的句 + 开了遮挡 + 还没出分 → 只给首词和词数,
                        // 凭上面的中文提示自己说;出分后(feedback)显示完整原句对照。
                        if isDrill && maskedOn && isUserTurn(s) && uiPhase != .feedback {
                            maskedPrompt(s)
                        } else {
                            sentenceWords(s)
                        }
                    }
                    .padding(.bottom, 20)
                    // 对方句自动播音频,不需要"听示范"行
                    if !(isDrill && !isUserTurn(s)) {
                        listenRow(s)
                            .padding(.bottom, 20)
                    }
                    if showFeedback, let result = lastResult {
                        FeedbackCard(target: s, result: result, userSamples: capturedSamples)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .padding(.bottom, 16)
                            .id("feedback")
                    }
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            // 出分后自动把反馈卡滚进可视区(卡片变高后曾被底部按钮区压住截断)。
            .onChange(of: showFeedback) { _, visible in
                guard visible else { return }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(120)) // 等卡片布局完成
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("feedback", anchor: .top)   // 顶部对齐:发音分先可见
                    }
                }
            }
        }
    }

    private func sentenceWords(_ s: SceneSentence) -> some View {
        let p = theme.palette
        let weakSet: Set<Int> = (uiPhase == .feedback)
            ? Set(lastResult?.weakIndexes ?? [])
            : []
        let tokens = Self.tokensWithPunct(en: s.en, words: s.words)
        return FlowLayout(spacing: 6) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { i, tk in
                let weak = weakSet.contains(i)
                (Text(tk.lead).foregroundColor(p.inkSoft)
                    + Text(tk.word)
                        .foregroundColor(weak ? p.accentDeep : p.ink)
                        .underline(weak, color: p.accent)
                    + Text(tk.trail).foregroundColor(p.inkSoft))
                    .font(AppFont.enSerif(size: 30))
            }
        }
    }

    // 对练:遮挡开关(看句读 ⇄ 凭提示盲说),这就是对练的第②档难度。
    private var maskToggle: some View {
        let p = theme.palette
        return Button {
            Haptics.tap()
            maskedOn.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: maskedOn ? "eye.slash.fill" : "eye")
                    .font(.system(size: 10, weight: .semibold))
                Text(maskedOn ? "盲说中" : "遮住句子")
            }
            .font(AppFont.zh(size: 11.5, weight: .medium))
            .foregroundStyle(maskedOn ? .white : p.inkSoft)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(maskedOn ? p.accent : p.surfaceAlt))
        }
        .buttonStyle(.plain)
    }

    // 对练②盲说的占位:首词 + 词数点位,不给原句。
    private func maskedPrompt(_ s: SceneSentence) -> some View {
        let p = theme.palette
        let first = s.words.first ?? ""
        let dots = Array(repeating: "▢", count: max(0, s.words.count - 1)).joined(separator: " ")
        return VStack(alignment: .leading, spacing: 10) {
            (Text(first + " ").foregroundColor(p.ink)
                + Text(dots).foregroundColor(p.inkMuted.opacity(0.6)))
                .font(AppFont.enSerif(size: 28))
            Text("凭中文提示自己说出来 · 共 \(s.words.count) 词 · 出分后显示原句")
                .font(AppFont.zh(size: 12))
                .foregroundStyle(p.inkMuted)
        }
    }

    // 把预分词 words 对齐回原句 en：每个词带上原文里的前导/尾随标点。
    // words 分词时剥掉了标点，直接渲染会让 "There are four. I live..."
    // 这类多分句糊成一团（与 web 版 tokensWithPunct 同一修复）。
    struct PunctToken: Hashable {
        let lead: String
        let word: String
        let trail: String
    }

    static func tokensWithPunct(en: String, words: [String]) -> [PunctToken] {
        var out: [PunctToken] = []
        var search = en.startIndex
        for w in words {
            guard !w.isEmpty, let r = en.range(of: w, range: search..<en.endIndex) else {
                out.append(PunctToken(lead: "", word: w, trail: ""))
                continue
            }
            let lead = en[search..<r.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            var j = r.upperBound
            var trail = ""
            while j < en.endIndex, !en[j].isWhitespace {
                trail.append(en[j])
                j = en.index(after: j)
            }
            out.append(PunctToken(lead: lead, word: w, trail: trail))
            search = j
        }
        return out
    }

    private func listenRow(_ s: SceneSentence) -> some View {
        let p = theme.palette
        return HStack(spacing: 10) {
            Button {
                Haptics.tap()
                if speaker.isSpeaking {
                    speaker.stop()
                } else {
                    speaker.speak(s, voice: s.preferredVoice, slow: false)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: speaker.isSpeaking ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(speaker.isSpeaking ? "播放中" : "听示范")
                }
                .font(AppFont.zh(size: 13, weight: .medium))
                .foregroundStyle(p.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Capsule().fill(p.surface))
                .overlay(Capsule().stroke(p.line, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                Haptics.tap()
                speaker.speak(s, voice: s.preferredVoice, slow: true)
            } label: {
                Text("慢速")
                    .font(AppFont.zh(size: 12, weight: .medium))
                    .foregroundStyle(p.inkSoft)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(p.surface))
                    .overlay(Capsule().stroke(p.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Controls

    private var controls: some View {
        let p = theme.palette
        return VStack(spacing: 14) {
            if let err = lastError {
                // Red banner when the recorder failed. Click to dismiss.
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                    Text(err)
                        .font(AppFont.zh(size: 12, weight: .medium))
                    Spacer(minLength: 0)
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .opacity(0.6)
                }
                .foregroundStyle(p.danger)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(p.danger.opacity(0.08))
                )
                .onTapGesture { lastError = nil }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            // Phase hint above the mic button. 固定高度、用透明度切换 —— 之前
            // 用 if 增删视图,点话筒的瞬间整列高度变化,按钮跟着跳位,看着像"话筒歪了"。
            // 出分后隐藏整个话筒区,把空间让给反馈卡(否则 170pt 话筒把反馈卡挤成一半)。
            if uiPhase != .feedback {
                Text(phaseHint)
                    .font(AppFont.zh(size: 13, weight: uiPhase == .idle ? .regular : .semibold))
                    .foregroundStyle(phaseHintColor)
                    .frame(height: 18)
                    .animation(.easeInOut(duration: 0.2), value: uiPhase)

                micButton
                    .frame(width: 170, height: 170)
                    // 对练:对方说话时话筒不可用,视觉同步弱化
                    .opacity(uiPhase == .listening ? 0.35 : 1)
                    .allowsHitTesting(uiPhase != .listening)
                    .animation(.easeInOut(duration: 0.2), value: uiPhase)

                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 11))
                    Text("点一下开始跟读 · 读完再点一下出分")
                }
                .font(AppFont.zh(size: 11.5))
                .foregroundStyle(p.inkMuted)
                .frame(height: 16)
                .padding(.top, -4)
                .opacity(uiPhase == .idle ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: uiPhase)
            }

            // When permission is denied, give a prominent one-tap shortcut
            // into Settings. The mic button stays visible so they understand
            // where recording would happen once permission is granted.
            if uiPhase == .denied {
                Button {
                    Haptics.tap()
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.fill").font(.system(size: 12))
                        Text("去「设置」打开麦克风和语音识别")
                    }
                    .font(AppFont.zh(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(p.accent))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Button("重录") {
                    Haptics.tap()
                    lastResult = nil
                    capturedSamples = []
                    uiPhase = .idle
                }
                .font(AppFont.zh(size: 13))
                .foregroundStyle(uiPhase == .feedback ? p.inkSoft : p.inkMuted)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .disabled(uiPhase != .feedback)

                // 下一句在空闲态也可点(跳过本句,不记分)——只有录音/评测中锁定。
                // 否则录不出有效音的用户会被锁死在一句上(防呆红条 → idle → 永远点不了)。
                Button { advance() } label: {
                    HStack(spacing: 6) {
                        Text(index == sentences.count - 1 ? "完成" : "下一句")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .font(AppFont.zh(size: 13, weight: .semibold))
                    .foregroundStyle(nextEnabled ? (p.isDark ? p.bg : .white) : p.inkMuted)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(nextEnabled ? p.ink : p.surfaceAlt))
                }
                .disabled(!nextEnabled)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // 录音主按钮 — 状态用「形变」讲一个连续的故事(Apple Voice Memos 语言):
    //   待录: 大圆 + 麦克风(双层影/顶部内高光/静态 halo,邀请感)
    //   录音: 圆形变成圆角方块(系统级「停止」隐喻,零学习成本)+ 真声浪环 + 走秒
    //   评测: 收回圆形,三点呼吸(自定义,不用系统转圈)
    // 交互仍是点击切换(micTapped);此处只做视图/动效,不碰业务逻辑。
    private var micButton: some View {
        let p = theme.palette
        let recording = uiPhase == .recording
        let analyzing = uiPhase == .analyzing
        let size: CGFloat = recording ? 64 : (analyzing ? 76 : 92)
        let corner: CGFloat = recording ? 20 : size / 2   // 圆→方靠一条 cornerRadius 动画完成

        return ZStack {
            // ① 静态 halo:待录时一圈极淡的品牌色光晕,给按钮"落座感"
            if uiPhase == .idle || uiPhase == .feedback {
                Circle()
                    .fill(p.accent.opacity(0.10))
                    .frame(width: 134, height: 134)
                    .blur(radius: 12)
            }

            // ② 真实音量驱动的声浪环(仅录音时;评测中不再假装在听)
            if recording {
                LiveWaveformRing(samples: recorder.levelSamples,
                                 color: p.accent,
                                 innerRadius: 54, maxLen: 26)
                    .frame(width: 170, height: 170)
                    .transition(.opacity)
            }

            // ③ 主按钮本体
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(LinearGradient(colors: [p.accent, p.accentDeep],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay( // 顶部内高光 — 质感的关键一层
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .fill(LinearGradient(colors: [.white.opacity(0.26), .clear],
                                                 startPoint: .top, endPoint: .center))
                            .padding(1.5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(.white.opacity(0.16), lineWidth: 0.8)
                    )
                    .frame(width: size, height: size)
                    // 双层影:近处环境影定形,远处品牌色影给氛围
                    .shadow(color: .black.opacity(0.10), radius: 2, y: 1)
                    .shadow(color: p.accent.opacity(recording ? 0.42 : 0.30),
                            radius: recording ? 22 : 15, y: 9)

                // 图标交叉淡变(同时在场,透明度+缩放过渡)——if/else 突切在
                // spring 形变中途交叉错位,是"话筒变歪"观感的另一半来源。
                Image(systemName: "mic.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                    .opacity(recording || analyzing ? 0 : 1)
                    .scaleEffect(recording || analyzing ? 0.55 : 1)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .opacity(recording ? 1 : 0)
                    .scaleEffect(recording ? 1 : 0.5)
                if analyzing {
                    AnalyzingDots()
                }
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.76), value: uiPhase)

            // ④ 录音走秒 — 确定感与仪式感
            if recording, let started = recordStartedAt {
                Text(started, style: .timer)
                    .font(AppFont.enSans(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(p.accentDeep)
                    .offset(y: 52)
                    .transition(.opacity)
            }
        }
        // 命中区固定 120pt,不随形变缩小(录音中小方块照样好点)
        .frame(width: 120, height: 120)
        .contentShape(Rectangle())
        .onTapGesture { micTapped() }
    }

    // MARK: - Tap-to-toggle recording

    // 点一下开始/结束。录音中再点 = 停止出分；识别中忽略。
    private func micTapped() {
        if uiPhase == .recording {
            // 防手抖:开始不到 1.2s 的"停止"点击视为误触(手指没离开又碰一下),
            // 忽略——否则还没开口就出低分"没听清楚"。
            if let started = recordStartedAt, Date().timeIntervalSince(started) < 1.2 {
                NSLog("[Practice] micTapped ignored — %.2fs after start", Date().timeIntervalSince(started))
                return
            }
            NSLog("[Practice] micTapped — stop recording")
            Haptics.soft()
            recorder.stop()
            return
        }
        startAttempt()
    }

    private func startAttempt() {
        guard uiPhase == .idle || uiPhase == .feedback else {
            NSLog("[Practice] startAttempt while uiPhase=%@ — ignored",
                  String(describing: uiPhase))
            return
        }
        NSLog("[Practice] startAttempt — starting recorder")

        Haptics.press()
        speaker.stop()
        lastResult = nil
        lastError = nil
        capturedSamples = []
        uiPhase = .recording
        recorder.start()

        // Handle start() failures synchronously. We can't rely on the
        // .onChange(recorder.phase) observer alone because if the same
        // failure repeats (e.g. "无法读取麦克风输入格式" twice in a row),
        // onChange dedupes by Equatable and doesn't fire the second time —
        // which would leave uiPhase stuck at .recording forever.
        switch recorder.phase {
        case .denied:
            uiPhase = .denied
            showPermissionAlert = true
            NSLog("[Practice] startAttempt: recorder.phase=.denied")
            return
        case .error(let msg):
            uiPhase = .idle
            lastError = msg
            Haptics.warning()
            NSLog("[Practice] startAttempt: recorder.phase=.error(%@)", msg)
            return
        case .recording:
            break   // expected happy path
        default:
            // start() should always land in .recording / .denied / .error.
            // Anything else means it bailed silently — don't leave the UI stuck.
            uiPhase = .idle
            lastError = "录音未能启动"
            NSLog("[Practice] startAttempt: recorder.phase=%@ unexpected",
                  String(describing: recorder.phase))
            return
        }

        recordSession += 1
        recordStartedAt = Date()
        // Safety cap so a forgotten tap doesn't record forever.
        if let sentence = sentences[safe: index] {
            scheduleAutoStop(target: sentence, session: recordSession)
        }
    }

    private func scheduleAutoStop(target: SceneSentence, session: Int) {
        // 纯安全网(防用户点了开始就忘/离开):给足朗读时间,正常读完是主动点停止。
        // 放宽到词×2.5+8,下限 15s、上限 40s——正常朗读绝不会先触发。
        let seconds = min(40, max(15, Double(target.words.count) * 2.5 + 8.0))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            // 只停「本次」录音:切句后旧 Task 到期时 session 不匹配 → 不误停新录音。
            // (这正是"才点开始就结束"的根因:旧 auto-stop 秒停了新录音。)
            guard uiPhase == .recording, recordSession == session else { return }
            NSLog("[Practice] auto-stop after %.0fs", seconds)
            recorder.stop()
        }
    }

    // Safety net for the rare case where SFSpeechRecognizer hangs in
    // .analyzing without firing either isFinal or an error. If we've been
    // stuck analyzing for 4 seconds, force finalize with whatever partial
    // transcript we have. Empty transcript falls through to "没听到 — 再按住
    // 试一次" in the scorer.
    private func scheduleAnalyzingTimeout() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard uiPhase == .analyzing else { return }
            NSLog("[Practice] analyzing timeout — force finalize (transcript=%@)",
                  recorder.transcript)
            finalizeRecognition()
        }
    }

    private func handleRecorderPhase(_ newPhase: SpeechRecorder.Phase) {
        switch newPhase {
        case .analyzing:
            uiPhase = .analyzing
            scheduleAnalyzingTimeout()
        case .finished:
            finalizeRecognition()
        case .error(let msg):
            // Park in .idle (so the mic button stays ready) and surface the
            // real reason in a red banner above the button.
            uiPhase = .idle
            lastError = msg
            lastResult = nil
            Haptics.warning()
            NSLog("[Practice] recorder error: %@", msg)
        case .denied(let reason):
            uiPhase = .denied
            print("[recorder denied] \(reason)")
        default:
            break
        }
    }

    private func finalizeRecognition() {
        guard !scoring else { return }   // timeout 与 .finished 可能都触发,只做一次
        guard let sentence = sentences[safe: index] else { return }
        scoring = true
        capturedSamples = recorder.levelSamples
        let transcript = recorder.transcript
        // 有录音 WAV → 腾讯 SOE 真发音评测;失败/无文件 → 回落旧的词匹配评分(离线也能用)
        if let wavURL = recorder.lastRecordedFileURL {
            // 防呆①:按一下就松(hold-to-talk 被当成点击) → 只有零点几秒空音频。
            // 不送评、不出 0 分打击,引导按住读完。WAV 头 44B + 0.4s@16k16bit ≈ 12.8KB。
            let wavBytes = ((try? FileManager.default.attributesOfItem(atPath: wavURL.path))?[.size] as? Int) ?? 0
            if wavBytes < 44 + 12800 {
                scoring = false
                uiPhase = .idle
                lastResult = nil
                lastError = "没听到声音 — 点话筒开始，读完整句再点一下"
                Haptics.warning()
                return
            }
            Task { @MainActor in
                do {
                    let soe = try await TencentSOE.evaluate(wavURL: wavURL, refText: sentence.en)
                    // 防呆②:SOE 正常返回但一个词都没识别到(静音/太轻) → 引导重读,不出 0 分。
                    if soe.words.isEmpty {
                        scoring = false
                        uiPhase = .idle
                        lastResult = nil
                        lastError = "没听清 — 大声读完这句，再点一下出分"
                        Haptics.warning()
                        return
                    }
                    applyScore(soe.toScoreResult(target: sentence, transcript: transcript))
                } catch {
                    NSLog("[Practice] SOE 失败,回落词匹配: %@", error.localizedDescription)
                    applyScore(PronunciationScorer.score(target: sentence, recognized: transcript))
                }
            }
        } else {
            applyScore(PronunciationScorer.score(target: sentence, recognized: transcript))
        }
    }

    private func applyScore(_ result: ScoreResult) {
        scoring = false
        lastResult = result
        if let soe = result.soe {   // 只有真实 SOE 评分留档;重录覆盖旧分
            soeByIndex[absoluteIndexForCurrent] = (result.overall, soe)
        }
        if !result.weakIndexes.isEmpty {
            sessionWeakAbsolute.insert(absoluteIndexForCurrent)
        }
        withAnimation(.easeOut(duration: 0.25)) { uiPhase = .feedback }
        if result.overall >= 80 {
            Haptics.success()
        } else if result.recognized.isEmpty {
            Haptics.warning()
        } else {
            Haptics.soft()
        }
    }

    // 下一句可点:已出分(feedback)或空闲(idle,允许跳过没读出分的句子);
    // 仅录音/评测中锁定,防止会话状态错乱。
    private var nextEnabled: Bool {
        uiPhase == .feedback || uiPhase == .idle
    }

    private func advance() {
        Haptics.select()
        speaker.stop()   // 对练:跳句/轮转时停掉对方正在播的音频
        if index < sentences.count - 1 {
            withAnimation(.easeOut(duration: 0.18)) {
                index += 1
                uiPhase = .idle
                lastResult = nil
                capturedSamples = []
            }
            stepTurn()   // 对练:新句若是对方句,自动开播
        } else {
            // End of session: merge weak indexes into the review queue.
            let weakIdxs = Array(sessionWeakAbsolute)
            store.recordPractice(scene: scene, tier: tier,
                                 sentencesCompleted: sentences.count,
                                 weakIndexes: weakIdxs)
            // 学习数据 S1:落 session 明细(真分句按索引序;drill 只统计轮到用户说的句,
            // 对方句是自动播的不算"练了")
            let scored = soeByIndex.keys.sorted().map { soeByIndex[$0]! }
            let mode = isDrill ? "drill" : (filteredIndexes != nil ? "review" : "practice")
            let spoken = isDrill ? sentences.filter(isUserTurn).count : sentences.count
            store.logSession(sceneId: scene.id, tierLevel: tier.level, mode: mode,
                             sentenceCount: spoken, scored: scored,
                             startedAt: sessionStartedAt)
            if let filtered = filteredIndexes {
                // In review mode, only clear sentences that actually
                // improved this pass. Sentences still in sessionWeakAbsolute
                // stay in the queue so the user can take another crack.
                // (Previous version unconditionally cleared everything, so
                // a user who re-practiced and still missed the word would
                // see the item disappear anyway — the queue was lying.)
                let improved = filtered.filter { !sessionWeakAbsolute.contains($0) }
                if !improved.isEmpty {
                    store.clearFromReviewQueue(sceneId: scene.id,
                                                tierLevel: tier.level,
                                                sentenceIndexes: improved)
                }
            }
            path.append(AppRoute.result(sceneId: scene.id, tierLevel: tier.level))
        }
    }

    // MARK: - Labels

    private var chipLabel: String {
        if isDrill {
            let mine = sentences[safe: index].map(isUserTurn) ?? true
            return mine ? "对练 · 🎤 轮到你说" : "对练 · 🎧 听对方说"
        }
        if filteredIndexes != nil {
            return "复练 · \(scene.title)"
        }
        return "\(scene.title) · 第 \(index + 1) 句"
    }

    private var phaseHint: String {
        switch uiPhase {
        case .idle:      return "点一下话筒 · 开始跟读"
        case .recording: return "● 正在录音 — 读完点一下出分"
        case .analyzing: return "评测中…"
        case .feedback:
            guard let r = lastResult else { return "" }
            if r.recognized.isEmpty { return "没听到 — 点话筒再试一次" }
            if r.overall >= 80 { return "很棒，继续" }
            return "还可以更自然"
        case .listening: return isDrill ? "对方在说 — 听完就轮到你" : "正在播放示范"
        case .denied:    return "需要麦克风和语音识别权限 · 点去设置"
        }
    }

    private var phaseHintColor: Color {
        let p = theme.palette
        switch uiPhase {
        case .recording: return p.accent
        case .feedback:
            guard let r = lastResult else { return p.inkSoft }
            return r.overall >= 80 ? p.sage : p.accentDeep
        case .denied:    return p.danger
        default:         return p.inkSoft
        }
    }
}

// MARK: - Analyzing indicator

// 评测中的三点呼吸(错峰渐隐渐显)。替代系统 ProgressView 转圈 —— 转圈是
// "系统在忙"的通用语言,三点呼吸更像"在听你说的话",与录音按钮同一气质。
private struct AnalyzingDots: View {
    @State private var on = false
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(.white)
                    .frame(width: 7, height: 7)
                    .opacity(on ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.16), value: on)
            }
        }
        .onAppear { on = true }
    }
}

// MARK: - Flow layout for variable-width words

// Lays out English word labels that naturally wrap. SwiftUI's built-in
// stack doesn't wrap; this is the minimum impl we need for the practice
// sentence display.
//
// Implementation note: items are placed top-aligned at the row's baseline
// (`y` advances by the previous row's full height before placing the next
// row). The earlier version vertical-centered each item against an
// in-progress `rowHeight` of 0, which produced negative y offsets and made
// the first word of every row visually overlap the previous row.

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    // Computed rows: each row is a list of subview indexes + the row's
    // total height. Doing this once per layout pass keeps placeSubviews
    // and sizeThatFits in agreement (they used to disagree, which made
    // SwiftUI place items into stale slots).
    private struct Row {
        var indexes: [Int] = []
        var height: CGFloat = 0
        var width: CGFloat = 0
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for (i, s) in subviews.enumerated() {
            let size = s.sizeThatFits(.unspecified)
            let prospective = rows[rows.count - 1].width
                + (rows[rows.count - 1].indexes.isEmpty ? 0 : spacing)
                + size.width
            if !rows[rows.count - 1].indexes.isEmpty && prospective > maxWidth {
                rows.append(Row())
            }
            var current = rows[rows.count - 1]
            if !current.indexes.isEmpty { current.width += spacing }
            current.indexes.append(i)
            current.width += size.width
            current.height = max(current.height, size.height)
            rows[rows.count - 1] = current
        }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let computed = rows(for: subviews, maxWidth: width)
        let height = computed.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(0, computed.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let computed = rows(for: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in computed {
            var x = bounds.minX
            for (j, idx) in row.indexes.enumerated() {
                let s = subviews[idx]
                let size = s.sizeThatFits(.unspecified)
                if j > 0 { x += spacing }
                // Align all items to the baseline of the row's tallest item.
                // For uniform-font sentences (our case) this is equivalent
                // to top-align, but it stays correct if a chip ever joins.
                s.place(at: CGPoint(x: x, y: y + row.height - size.height),
                        proposal: .unspecified)
                x += size.width
            }
            y += row.height + spacing
        }
    }
}

// Safe subscript for arrays.
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
