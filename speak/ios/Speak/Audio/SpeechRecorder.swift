import Foundation
import AVFoundation
import Speech
import Combine

// Recording + speech-to-text, backed by AVAudioRecorder writing a temp
// WAV file. Earlier iteration used AVAudioEngine with an input tap +
// live SFSpeechAudioBufferRecognitionRequest (what Apple's own sample
// code uses) but on iOS 26 we hit a known bug where after several
// start/stop cycles the engine reports isRunning=true but never
// delivers any audio buffers to the tap (the "zombie engine"
// symptom). AVAudioRecorder sits on AudioQueueServices instead and
// is famously boring + reliable, so we use it.
//
// End-to-end flow per recording session:
//   1. start() opens a file-backed AVAudioRecorder writing 16 kHz
//      16-bit mono LE PCM (WAV container).
//   2. A 30 Hz timer polls the recorder's meter for the waveform UI.
//   3. stop() flushes the file, reads it, strips the 44-byte WAV header,
//      and kicks off SFSpeechURLRecognitionRequest for the transcript.
//   4. When Apple's recognizer finishes, phase transitions to .finished;
//      PracticeScreen reads transcript and calls PronunciationScorer.
//
// `lastRecordedPCM16k` is kept around in case we later swap in a
// native phoneme-scoring SDK (iFlytek MSC / Tencent SOE) that wants
// raw PCM; today's scorer only needs the transcript.
//
// All @Published properties are @MainActor so views bind directly.

@MainActor
final class SpeechRecorder: ObservableObject {

    enum Phase: Equatable {
        case idle
        case denied(reason: String)
        case recording
        case analyzing
        case finished
        case error(String)
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var currentLevel: Float = 0      // 0…1, updated ~30 Hz
    @Published private(set) var levelSamples: [Float] = []   // Rolling buffer for waveform
    @Published private(set) var transcript: String = ""

    // Last recording's raw PCM16 16 kHz mono bytes (WAV header stripped).
    // Read by PracticeScreen → PronunciationScorer → IFlytekEvaluator.
    private(set) var lastRecordedPCM16k = Data()

    private var recorder: AVAudioRecorder?
    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var meterTimer: Timer?
    private var currentFileURL: URL?
    /// 最近一次录音的 16k WAV 文件(供腾讯 SOE 真评测读取)。录音 stop 后有效。
    var lastRecordedFileURL: URL? { currentFileURL }

    // Bumped on every start() so that a recognition callback from a
    // previous session can't reach in and mutate phase / transcript on
    // the current one. This was a real failure mode: tap mic → release
    // partial → tap again → the cancelled prior recognition task's
    // completion fired with a non-standard error code, got mapped to
    // .error, and turned the whole screen red mid-recording.
    private var sessionToken: Int = 0

    // True between start() and stop(). The async second-stage of start()
    // checks this so a finger-up before the recorder actually came up
    // doesn't accidentally start a phantom recording.
    private var wantsToRecord: Bool = false

    private let maxSampleCount = 96

    init(locale: Locale = Locale(identifier: "en-US")) {
        self.recognizer = SFSpeechRecognizer(locale: locale)
    }

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let micGranted: Bool = await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        guard micGranted else {
            phase = .denied(reason: "需要麦克风权限来录制你的跟读。请到设置里开启。")
            return false
        }
        let speechStatus: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            phase = .denied(reason: "需要语音识别权限来给你打分。请到设置里开启。")
            return false
        }
        return true
    }

    // MARK: - Lifecycle

    func start() {
        stop()  // Clean any previous session first.

        // New session — any in-flight callbacks from prior sessions
        // will see a stale token and bail.
        sessionToken &+= 1
        wantsToRecord = true

        // Reset transcript / waveform synchronously so the UI renders
        // with the new recording's clean state.
        transcript = ""
        levelSamples = []
        currentLevel = 0
        lastRecordedPCM16k = Data()

        // Permission gates. We treat .undetermined as "try anyway and let
        // iOS prompt" — happens on a fresh install before `.task` finishes.
        let micStatus = AVAudioApplication.shared.recordPermission
        if micStatus == .denied {
            phase = .denied(reason: "没有麦克风权限 · 去设置里打开")
            wantsToRecord = false
            return
        }
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        if speechStatus == .denied || speechStatus == .restricted {
            phase = .denied(reason: "没有语音识别权限 · 去设置里打开")
            wantsToRecord = false
            return
        }

        // ── Optimistic phase flip ────────────────────────────────────
        // Surface .recording immediately so the UI repaints with the
        // pulse-and-scale animation on the very next runloop. The heavy
        // setup (session config + AudioQueue init, ~100-200 ms) runs in
        // a deferred dispatch so it doesn't block SwiftUI's render. This
        // is what makes the press feel snappy instead of "did I tap it?".
        phase = .recording
        let myToken = sessionToken

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // If user already released, or a newer session has started,
            // bail out — don't begin a phantom recording.
            guard self.sessionToken == myToken, self.wantsToRecord else {
                NSLog("[Recorder] deferred start cancelled (token mismatch or released)")
                return
            }
            self.completeStart()
        }
    }

    private func completeStart() {
        // 录音与示范播放共用一个 session,配置收在 AudioSessionCoordinator。
        // 这里刻意不先 setActive(false) 再 true —— 早期版本那样做会在第二次
        // 录音时触发竞态、弹红条;setCategory 同参数幂等,直接确保配置生效即可。
        AudioSessionCoordinator.activateShared()

        // Fresh file per session. Temp dir is auto-cleaned by iOS.
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("speak-\(UUID().uuidString).wav")
        currentFileURL = fileURL

        // 16 kHz 16-bit signed LE mono PCM — matches what most speech
        // backends want, and AVAudioRecorder writes a WAV directly so
        // we skip resampling.
        let settings: [String: Any] = [
            AVFormatIDKey:           kAudioFormatLinearPCM,
            AVSampleRateKey:         16000.0,
            AVNumberOfChannelsKey:   1,
            AVLinearPCMBitDepthKey:  16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey:    false,
        ]

        // Two-attempt setup. AVAudioRecorder occasionally fails the
        // first time when the previous recording's resources haven't
        // been fully released by the audio queue layer (especially
        // common when the user mashes the mic in quick succession).
        // A single 80ms retry recovers from that without bothering
        // the user with a red banner.
        var lastError: String? = nil
        for attempt in 1...2 {
            do {
                let r = try AVAudioRecorder(url: fileURL, settings: settings)
                r.isMeteringEnabled = true
                if r.prepareToRecord(), r.record() {
                    recorder = r
                    NSLog("[Recorder] started attempt=%d file=%@",
                          attempt, fileURL.lastPathComponent)
                    lastError = nil
                    break
                } else {
                    lastError = "AVAudioRecorder refused to start"
                    NSLog("[Recorder] attempt %d: prepareToRecord/record returned false",
                          attempt)
                }
            } catch {
                lastError = error.localizedDescription
                NSLog("[Recorder] attempt %d failed: %@", attempt, lastError!)
            }
            if attempt == 1 {
                // Brief settling time + bounce the session before retry.
                // 重配也走统一入口,别在这里把 mode 打回 .measurement(会让之后的
                // 示范播放没声音)。
                Thread.sleep(forTimeInterval: 0.08)
                AudioSessionCoordinator.deactivate()
                AudioSessionCoordinator.activateShared()
            }
        }
        if let err = lastError {
            phase = .error("录音启动失败：\(err)")
            wantsToRecord = false
            return
        }

        // 30 Hz meter polling for the live waveform UI. Timer runs on
        // main so we can mutate @Published props directly.
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0,
                                          repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMeter()
            }
        }
        // phase already at .recording from start(); confirm in case the
        // optimistic flip got bumped.
        if phase != .recording {
            phase = .recording
        }
    }

    func stop() {
        meterTimer?.invalidate()
        meterTimer = nil

        // Cancel any in-flight recognition task from a previous cycle.
        recognitionTask?.cancel()
        recognitionTask = nil

        // Mark intent: if start()'s deferred completeStart hasn't run
        // yet, it'll see this and skip launching the recorder.
        wantsToRecord = false

        guard let r = recorder else {
            // No active recorder — either we were never recording, or
            // the user released between start() and its deferred
            // completeStart(). In the latter case phase is still
            // .recording (set optimistically); flip it back to .idle
            // so the UI doesn't pretend we recorded something.
            if phase == .recording {
                phase = .idle
            }
            return
        }
        r.stop()
        recorder = nil

        // DO NOT deactivate the audio session here — the user is likely
        // about to press the mic again, and ping-ponging the session
        // activation between recordings trips a race in iOS's async
        // .notifyOthersOnDeactivation broadcast. The session gets torn
        // down once, in deactivateSession(), when the screen goes away.

        // Flip to .analyzing BEFORE kicking off recognition so the UI
        // shows the spinner immediately. recognizeFile updates to
        // .finished when Apple's transcript callback returns.
        if phase == .recording {
            phase = .analyzing
        }

        // Capture the token + URL for the deferred read. AVAudioRecorder.stop()
        // returns synchronously but the file-write flush isn't always
        // complete by the time the call returns (especially short
        // recordings). Reading the WAV header on the next runloop tick
        // gives the audio queue ~16-50 ms to finish closing the file —
        // enough to dodge the "second recording reads truncated WAV →
        // empty Apple transcript → 0%" failure mode.
        let myToken = sessionToken
        let url = currentFileURL

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // If a newer session started already, this read is stale.
            guard self.sessionToken == myToken else {
                NSLog("[Recorder] deferred read cancelled — newer session in flight")
                return
            }
            if let url = url, FileManager.default.fileExists(atPath: url.path) {
                self.extractPCMFromWAV(url: url)
                if !self.lastRecordedPCM16k.isEmpty {
                    self.recognizeFile(url: url, token: myToken)
                } else {
                    NSLog("[Recorder] WAV had no audio data")
                    self.phase = .finished
                }
            } else {
                NSLog("[Recorder] WAV file missing after stop")
                self.phase = .finished
            }
        }
    }

    /// Releases the shared AVAudioSession. Call this when the
    /// recording screen goes away (e.g. NavigationStack pop) so other
    /// apps regain the microphone. Normally you don't call this
    /// between recordings — stop() leaves the session alive on purpose.
    func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Meter polling

    private func updateMeter() {
        guard let r = recorder else { return }
        r.updateMeters()
        // averagePower returns dBFS in [-160, 0]. Apply the same -55 dB
        // floor we used in the AVAudioEngine path for a consistent
        // waveform feel between the two implementations.
        let db = r.averagePower(forChannel: 0)
        let normalized = max(0, min(1, (db + 55) / 55))
        currentLevel = normalized
        levelSamples.append(normalized)
        if levelSamples.count > maxSampleCount {
            levelSamples.removeFirst(levelSamples.count - maxSampleCount)
        }
    }

    // MARK: - File → PCM

    // AVAudioRecorder writes a plain uncompressed WAV when we ask for
    // kAudioFormatLinearPCM. The standard WAV header is 44 bytes: RIFF
    // container, fmt chunk, data chunk. Everything after byte 44 is raw
    // PCM samples at the format we specified. That's exactly what
    // iFlytek's "audio/L16;rate=16000; aue=raw" wants.
    //
    // We don't validate the header's internal fields — we wrote it
    // ourselves 2 seconds ago, the format is guaranteed. If some iOS
    // version ever slips a FLLR padding chunk in before data (rare but
    // documented) we'd need a real parser, but for now the 44-byte
    // assumption is correct on every iOS release we've seen.
    private func extractPCMFromWAV(url: URL) {
        guard let data = try? Data(contentsOf: url), data.count > 44 else {
            lastRecordedPCM16k = Data()
            NSLog("[Recorder] WAV file too small or unreadable")
            return
        }
        lastRecordedPCM16k = data.subdata(in: 44..<data.count)
        NSLog("[Recorder] extracted %d PCM bytes (file %d bytes)",
              lastRecordedPCM16k.count, data.count)
    }

    // MARK: - File → transcript

    private func recognizeFile(url: URL, token: Int) {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            NSLog("[Recorder] SFSpeechRecognizer unavailable, skipping transcript")
            phase = .finished
            return
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                // If a newer session has started, this callback is for a
                // dead recording — drop it on the floor instead of
                // letting it stomp transcript / phase on the live one.
                guard token == self.sessionToken else {
                    NSLog("[Recorder] stale callback (token=%d, current=%d) — ignored",
                          token, self.sessionToken)
                    return
                }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    if result.isFinal {
                        NSLog("[Recorder] Apple final: '%@'", self.transcript)
                        self.phase = .finished
                        self.recognitionTask = nil
                    }
                }
                if let error {
                    let ns = error as NSError
                    NSLog("[Recorder] Apple error: %@ (code=%d)",
                          error.localizedDescription, ns.code)
                    // Most non-cancel errors from SFSpeech are still
                    // user-recoverable — empty transcript flows through
                    // to "没听到 — 再按住试一次" without alarming the user.
                    // We only escalate to a red banner for the few errors
                    // that genuinely need attention (e.g. server / auth).
                    let benign: Set<Int> = [
                        1,    // cancelled
                        203,  // no speech detected
                        209,  // local recognition unavailable / quota
                        216,  // recognition request was not started
                        1101, // local recognition failed
                        1107, // local recognition unavailable
                        1110, // recognition timed out
                    ]
                    if benign.contains(ns.code) {
                        if self.phase != .finished { self.phase = .finished }
                    } else {
                        self.phase = .error(error.localizedDescription)
                    }
                    self.recognitionTask = nil
                }
            }
        }
    }
}
