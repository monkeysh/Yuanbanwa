import SwiftUI

// 模拟考官(MVP):AI 演剑桥 Part 1 考官,学生自由作答。
// 循环:考官问(DeepSeek 生成,AVSpeech 播) → 学生点话筒自由说(SFSpeech 转写)
//      → 转写送后端 → 考官回应+下一问 → … → 6 问后结束 → 中文报告。
// 后端 /api/soe/chat 无状态,历史由本屏携带。

struct ExamScreen: View {
    let exam: String        // KET / PET / FCE
    let topic: String       // 英文话题(送考官 prompt)
    let topicZh: String     // 中文话题(标题展示)
    let examinerVoice: String   // "rosie" 女考官 / "chris" 男考官
    @Binding var path: NavigationPath

    // 考官身份:声线决定 TTS 嗓音、头像、名字("女=Rosie / 男=Chris")。
    private var isMale: Bool { examinerVoice == "chris" }
    private var ttsVoice: VoicePreference { isMale ? .chris : .rosie }
    private var examinerName: String { isMale ? "Chris" : "Rosie" }
    // 每场题量,须与后端 examMaxQ 一致(KET8/PET9/FCE10)。
    private var maxQ: Int { exam == "FCE" ? 8 : exam == "PET" ? 7 : 6 }

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var recorder = SpeechRecorder()
    @StateObject private var speaker = SpeechSpeaker()

    struct Bubble: Identifiable, Equatable {
        let id = UUID()
        let mine: Bool
        var text: String
        var zh: String = ""   // 考官问题的中文提示(KET/PET 学生英语不够时看得懂在问什么)
    }
    struct QA { let q: String; var a: String }
    struct ExamReport { let overall: String; let tips: [String]; let models: [(q: String, model: String)] }

    enum Phase: Equatable { case connecting, examinerSpeaking, ready, recording, transcribing, thinking, ended, failed(String) }

    @State private var phase: Phase = .connecting
    @State private var bubbles: [Bubble] = []
    @State private var history: [QA] = []
    @State private var pendingQuestion: String? = nil   // 已问出、待学生回答的问题
    @State private var report: ExamReport? = nil
    @State private var permissionChecked = false
    @State private var pronScores: [SOEResult] = []   // 每题 SOE 发音评分累积(考后聚合)
    @State private var restartTick = 0                 // "再练一轮"触发滚回顶部
    @State private var variant = Int.random(in: 0..<8) // 每场随机切入角度(与后端 VARIANTS 8 个一致),"再练一次"换新角度
    // 学习数据 S5:考官场次落盘(每场一条,mode="exam";pronScores 是真实 SOE 分)
    @State private var sessionStart = Date()
    @State private var sessionLogged = false

    // 发音评分聚合(各题平均;流利/完整原始 0–1 → 0–100)。
    // ⚠️ 自由说模式下腾讯返回完整度 = -1(无参考文本,该维度不适用)。
    // 这种维度必须显示为「—」,绝不能 clamp 成 0 分冒充真实分数(假分红线)。
    private var avgPron: (overall: Int, acc: Int, flu: Int, comp: Int?)? {
        guard !pronScores.isEmpty else { return nil }
        let n = Double(pronScores.count)
        let clamp = { (v: Double) -> Int in Int((min(100, max(0, v))).rounded()) }
        let comps = pronScores.map(\.pronCompletion).filter { $0 >= 0 }   // -1 = 不适用,剔除
        return (clamp(pronScores.map(\.suggestedScore).reduce(0, +) / n),
                clamp(pronScores.map(\.pronAccuracy).reduce(0, +) / n),
                clamp(pronScores.map { $0.pronFluency * 100 }.reduce(0, +) / n),
                comps.isEmpty ? nil : clamp(comps.reduce(0, +) / Double(comps.count) * 100))
    }

    private let endpoint = URL(string: "https://speak.yuanbanwa.top/api/soe/chat")!

    var body: some View {
        let p = theme.palette
        VStack(spacing: 0) {
            topBar
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        examinerBadge.id("examTop")
                        ForEach(bubbles) { b in bubbleView(b) }
                        if phase == .thinking || phase == .connecting {
                            typingBubble
                        }
                        if let r = report { reportCard(r).id("report") }
                        Color.clear.frame(height: 8).id("tail")
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                }
                .scrollIndicators(.hidden)
                .onChange(of: bubbles) { _, _ in
                    withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("tail", anchor: .bottom) }
                }
                .onChange(of: report != nil) { _, has in
                    guard has else { return }
                    withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("report", anchor: .bottom) }
                }
                // 再练一轮:滚回顶部,让用户看到新一场从头开始(不再停在旧报告底部)
                .onChange(of: restartTick) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("examTop", anchor: .top) }
                }
            }
            bottomBar
        }
        .background(p.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if !permissionChecked {
                permissionChecked = true
                _ = await recorder.requestPermissions()
            }
            await startExam()
        }
        .onChange(of: recorder.phase) { _, ph in
            switch ph {
            case .analyzing: if phase == .recording { phase = .transcribing }
            case .finished: if phase == .recording || phase == .transcribing { submitAnswer(recorder.transcript) }
            case .error(let msg): if phase == .recording || phase == .transcribing { phase = .failed(msg) }
            default: break
            }
        }
        // 考官 TTS 播完 → 轮到学生
        .onChange(of: speaker.isSpeaking) { _, speaking in
            if !speaking && phase == .examinerSpeaking { phase = .ready }
        }
        .onDisappear {
            recorder.stop(); recorder.deactivateSession(); speaker.stop()
        }
    }

    // MARK: - 流程

    private func startExam() async {
        phase = .connecting
        await examinerTurn(answer: nil)
    }

    private func submitAnswer(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { phase = .ready; return }
        bubbles.append(Bubble(mine: true, text: text))
        if pendingQuestion != nil { history[history.count - 1].a = text }
        // 并行评发音,不阻塞对话。每题一个独立 WAV(UUID 命名不覆盖),考后报告聚合。
        // ⚠️ 必须用自由说模式:开放式作答没有标准答案,旧版把转写文本当参考送评,
        // 完整度恒满分、分数虚高(用户验收实测"答得又短又差照样高分")。
        if let wav = recorder.lastRecordedFileURL {
            Task {
                if let soe = try? await SOEClient.evaluate(wavURL: wav, refText: text, mode: .freeSpeak), !soe.words.isEmpty {
                    await MainActor.run { pronScores.append(soe) }
                }
            }
        }
        phase = .thinking
        Task { await examinerTurn(answer: text) }
    }

    private func examinerTurn(answer: String?) async {
        do {
            let body: [String: Any] = [
                "exam": exam, "topic": topic, "variant": variant,
                "history": history.map { ["q": $0.q, "a": $0.a] },
            ]
            let out = try await postJSON(body)
            let reaction = (out["reaction"] as? String) ?? ""
            let question = (out["question"] as? String) ?? ""
            let questionZh = (out["questionZh"] as? String) ?? ""
            let isEnd = (out["isEnd"] as? Bool) ?? false
            var speech = reaction
            if !reaction.isEmpty { bubbles.append(Bubble(mine: false, text: reaction)) }
            if !question.isEmpty {
                bubbles.append(Bubble(mine: false, text: question, zh: questionZh))
                history.append(QA(q: question, a: ""))
                pendingQuestion = question
                speech = speech.isEmpty ? question : speech + " " + question
            }
            if isEnd {
                phase = .ended
                // 学习数据 S5:落一条考官 session(sceneId=英文topic,tierLevel=考试级)。
                // pronScores 为空(全程降级)→ scored 为空 → avg 全 nil,不造假分。
                if !sessionLogged {
                    sessionLogged = true
                    let clampI = { (v: Double) -> Int in Int(min(100, max(0, v)).rounded()) }
                    // 完整度:自由说模式返回 -1(不适用)。原样保留负值当哨兵传下去,
                    // PracticeSession.build 会剔除它,不会算成 0 分拉低成长页平均。
                    let scored = pronScores.map { r in
                        (overall: clampI(r.suggestedScore),
                         soe: SOEDetail(accuracy: clampI(r.pronAccuracy),
                                        fluency: clampI(r.pronFluency * 100),
                                        completion: r.pronCompletion < 0 ? -1 : clampI(r.pronCompletion * 100),
                                        words: r.words.map { SOEWordDetail(word: $0.word, accuracy: $0.accuracy, phones: $0.phones) }))
                    }
                    store.logSession(sceneId: topic, tierLevel: exam, mode: "exam",
                                     sentenceCount: history.count, scored: scored,
                                     startedAt: sessionStart, examTopicZh: topicZh)
                }
                if !speech.isEmpty { speaker.speakText(speech, voice: ttsVoice) }
                await fetchReport()
            } else {
                phase = .examinerSpeaking
                if speech.isEmpty { phase = .ready }
                else { speaker.speakText(speech, voice: ttsVoice) }
            }
        } catch {
            phase = .failed("考官掉线了 — 检查网络后点重试")
        }
    }

    private func fetchReport() async {
        do {
            let out = try await postJSON(["mode": "report", "exam": exam,
                                          "history": history.map { ["q": $0.q, "a": $0.a] }])
            let models = ((out["models"] as? [[String: Any]]) ?? []).compactMap { d -> (q: String, model: String)? in
                guard let q = d["q"] as? String, let m = d["model"] as? String else { return nil }
                return (q, m)
            }
            report = ExamReport(overall: (out["overall"] as? String) ?? "",
                                tips: (out["tips"] as? [String]) ?? [],
                                models: models)
        } catch { /* 报告失败不阻塞,保留结束态 */ }
    }

    private func postJSON(_ body: [String: Any]) async throws -> [String: Any] {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.badServerResponse)
        }
        return obj
    }

    private func micTapped() {
        switch phase {
        case .ready:
            Haptics.press()
            speaker.stop()
            phase = .recording
            recorder.start()
        case .recording:
            Haptics.soft()
            recorder.stop()
        case .failed:
            phase = history.isEmpty ? .connecting : .thinking
            Task { await examinerTurn(answer: nil) }
        default: break
        }
    }

    // MARK: - UI 组件

    private var topBar: some View {
        let p = theme.palette
        return HStack(spacing: 12) {
            Button {
                Haptics.tap(); recorder.stop(); speaker.stop(); dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(p.inkSoft)
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text("模拟考官 · \(exam)")
                    .font(AppFont.zh(size: 15, weight: .semibold))
                    .foregroundStyle(p.ink)
                Text(topicZh)
                    .font(AppFont.zh(size: 11))
                    .foregroundStyle(p.inkMuted)
            }
            Spacer()
            Text("\(min(history.count, maxQ))/\(maxQ) 问")
                .font(AppFont.enSans(size: 12, weight: .semibold))
                .foregroundStyle(p.inkSoft)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // 考官头像:女考官=Rosie / 男考官=Chris,均真人皮克斯圆头像(与外刊生态同款)。
    private func examinerAvatar(_ size: CGFloat) -> some View {
        let p = theme.palette
        return Image(isMale ? "chris-avatar" : "rosie-avatar")
            .resizable().scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(p.line, lineWidth: 1))
    }

    private var examinerBadge: some View {
        let p = theme.palette
        return HStack(spacing: 8) {
            examinerAvatar(30)
            VStack(alignment: .leading, spacing: 1) {
                Text("考官 \(examinerName)")
                    .font(AppFont.zh(size: 12.5, weight: .semibold))
                    .foregroundStyle(p.inkSoft)
                Text("像真实考试一样,听懂就大胆答")
                    .font(AppFont.zh(size: 10.5))
                    .foregroundStyle(p.inkMuted)
            }
        }
        .padding(.vertical, 6)
    }

    private func bubbleView(_ b: Bubble) -> some View {
        let p = theme.palette
        return HStack(alignment: .bottom, spacing: 8) {
            if b.mine {
                Spacer(minLength: 44)
            } else {
                examinerAvatar(32)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(b.text)
                    .font(b.mine ? AppFont.zh(size: 15) : AppFont.enSerif(size: 17))
                    .foregroundStyle(b.mine ? .white : p.ink)
                // 中文提示:英语不够时也知道考官在问什么(KET/PET 是 A2/B1,学生看不懂就没法答)
                if !b.zh.isEmpty {
                    Text(b.zh)
                        .font(AppFont.zh(size: 12))
                        .foregroundStyle(p.inkMuted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(b.mine ? AnyShapeStyle(p.accent) : AnyShapeStyle(p.surface))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(b.mine ? .clear : p.line, lineWidth: 1))
            )
            if !b.mine { Spacer(minLength: 44) }
        }
    }

    private var typingBubble: some View {
        let p = theme.palette
        return HStack(alignment: .bottom, spacing: 8) {
            examinerAvatar(32)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(p.inkMuted).frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.surface)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(p.line, lineWidth: 1)))
            Spacer(minLength: 44)
        }
        .opacity(0.7)
    }

    // v == nil:该维度本次不适用(如自由说模式无完整度),显示「—」而不是 0 分
    private func pronDim(_ label: String, _ v: Int?, big: Bool = false) -> some View {
        let p = theme.palette
        return VStack(spacing: 2) {
            Text(v.map(String.init) ?? "—")
                .font(AppFont.enSerif(size: big ? 22 : 17))
                .foregroundStyle(big ? p.accentDeep : p.ink)
            Text(label)
                .font(AppFont.zh(size: 10))
                .foregroundStyle(p.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(big ? p.accent.opacity(0.12) : p.surfaceAlt))
    }

    private func reportCard(_ r: ExamReport) -> some View {
        let p = theme.palette
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 13))
                Text("考官点评").font(AppFont.zh(size: 14, weight: .semibold))
            }
            .foregroundStyle(p.sage)
            Text(r.overall)
                .font(AppFont.zh(size: 13.5))
                .foregroundStyle(p.ink)
                .lineSpacing(3)
            // 发音评分(SOE 聚合各题):考试同时评"说得对不对 + 发音准不准"
            if let pron = avgPron {
                HStack(spacing: 8) {
                    pronDim("发音", pron.overall, big: true)
                    pronDim("准确", pron.acc)
                    pronDim("流利", pron.flu)
                    pronDim("完整", pron.comp)
                }
                .padding(.top, 2)
            }
            ForEach(Array(r.tips.enumerated()), id: \.offset) { i, tip in
                HStack(alignment: .top, spacing: 6) {
                    Text("\(i + 1).").font(AppFont.zh(size: 12.5, weight: .semibold)).foregroundStyle(p.accentDeep)
                    Text(tip).font(AppFont.zh(size: 12.5)).foregroundStyle(p.inkSoft).lineSpacing(2)
                }
            }
            // 范文区:每题给一个贴级别的优秀示范,让学员照着学(用户③)
            if !r.models.isEmpty {
                Rectangle().fill(p.line).frame(height: 1).padding(.vertical, 3)
                HStack(spacing: 6) {
                    Image(systemName: "text.book.closed.fill").font(.system(size: 12))
                    Text("参考回答 · 照着这样说").font(AppFont.zh(size: 13, weight: .semibold))
                }
                .foregroundStyle(p.accentDeep)
                ForEach(Array(r.models.enumerated()), id: \.offset) { _, m in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(m.q)
                            .font(AppFont.enSans(size: 12))
                            .foregroundStyle(p.inkMuted)
                        Text(m.model)
                            .font(AppFont.enSerif(size: 15))
                            .foregroundStyle(p.ink)
                            .lineSpacing(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(p.surfaceAlt))
                }
            }
            Button {
                Haptics.tap()
                bubbles = []; history = []; report = nil; pendingQuestion = nil; pronScores = []
                sessionStart = Date(); sessionLogged = false   // 新一场新 session
                variant = Int.random(in: 0..<8)   // 换个切入角度,下一场问不同的题
                restartTick += 1
                Task { await startExam() }
            } label: {
                Text("再练一轮")
                    .font(AppFont.zh(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(p.accent))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.surface)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(p.line, lineWidth: 1)))
    }

    private var bottomBar: some View {
        let p = theme.palette
        let recording = phase == .recording
        return VStack(spacing: 10) {
            Text(hint)
                .font(AppFont.zh(size: 12.5, weight: recording ? .semibold : .regular))
                .foregroundStyle(recording ? p.accent : (phase == .failed("") ? p.danger : p.inkSoft))
                .frame(height: 16)
            ZStack {
                RoundedRectangle(cornerRadius: recording ? 18 : 34, style: .continuous)
                    .fill(LinearGradient(colors: [p.accent, p.accentDeep],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: recording ? 18 : 34, style: .continuous)
                        .fill(LinearGradient(colors: [.white.opacity(0.24), .clear], startPoint: .top, endPoint: .center))
                        .padding(1.5))
                    .frame(width: recording ? 56 : 68, height: recording ? 56 : 68)
                    .shadow(color: p.accent.opacity(0.35), radius: 14, y: 7)
                Image(systemName: "mic.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .opacity(recording ? 0 : 1)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.white).frame(width: 16, height: 16)
                    .opacity(recording ? 1 : 0)
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: phase)
            .contentShape(Rectangle())
            .onTapGesture { micTapped() }
            .opacity(micEnabled ? 1 : 0.35)
            .allowsHitTesting(micEnabled || isFailed)
        }
        .padding(.top, 8)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity)
        .background(p.bg)
    }

    private var isFailed: Bool { if case .failed = phase { return true }; return false }
    private var micEnabled: Bool { phase == .ready || phase == .recording }

    private var hint: String {
        switch phase {
        case .connecting:       return "考官入场中…"
        case .examinerSpeaking: return "🎧 考官在说 — 听完就轮到你"
        case .ready:            return "点一下话筒 · 用英语自由回答"
        case .recording:        return "● 正在听你说 — 说完点一下"
        case .transcribing:     return "整理你的回答…"
        case .thinking:         return "考官在想…"
        case .ended:            return "考试结束 — 看看考官点评"
        case .failed(let m):    return m.isEmpty ? "出错了 — 点话筒重试" : m
        }
    }
}
