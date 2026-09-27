import Foundation
import AVFoundation

// Plays the target sentence:
//   1. Prefers a bundled native-speaker clip (阿黛/小何) when we have one.
//   2. Falls back to iOS TTS (AVSpeechSynthesizer) with a voice that matches
//      the user's preference (美式 → en-US, 英式 → en-GB).
// Slow mode reduces playback rate — works uniformly for both paths.

@MainActor
final class SpeechSpeaker: NSObject, ObservableObject {

    @Published private(set) var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public API

    func speak(_ sentence: SceneSentence, voice: VoicePreference, slow: Bool = false) {
        stop()
        if let url = AudioLibrary.clipURL(for: sentence, voice: voice) {
            playClip(url, slow: slow)
        } else {
            speakTTS(text: sentence.en, voice: voice, slow: slow)
        }
    }

    // Kept for screens that only have raw text (e.g. demo sentences).
    func speakText(_ text: String, voice: VoicePreference = .rosie, slow: Bool = false) {
        stop()
        speakTTS(text: text, voice: voice, slow: slow)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if let p = player, p.isPlaying {
            p.stop()
        }
        player = nil
        isSpeaking = false
    }

    // MARK: - Native-clip path

    private func playClip(_ url: URL, slow: Bool) {
        activatePlaybackSession()
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.enableRate = true
            p.rate = slow ? 0.75 : 1.0
            p.prepareToPlay()
            p.play()
            self.player = p
            self.isSpeaking = true
        } catch {
            // Fall through silently — UI can retry or the user can try
            // slow mode (TTS). Logging helps triage bundling issues.
            print("[speaker] clip playback failed: \(error.localizedDescription)")
        }
    }

    // MARK: - TTS path

    private func speakTTS(text: String, voice: VoicePreference, slow: Bool) {
        let utterance = AVSpeechUtterance(string: text)
        // 按声线性别挑系统嗓音(男考官 Chris → 男声);筛不到回落 locale 默认。
        let lang = voice.fallbackLocale
        let wantMale = (voice == .chris)
        utterance.voice = AVSpeechSynthesisVoice.speechVoices().first {
            $0.language == lang && $0.gender == (wantMale ? .male : .female)
        } ?? AVSpeechSynthesisVoice(language: lang)
        utterance.rate = slow
            ? AVSpeechUtteranceDefaultSpeechRate * 0.75
            : AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        activatePlaybackSession()
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    // 与录音共用一套 session 配置(见 AudioSessionCoordinator):此前这里切
    // `.playback` 且吞掉错误,录音后切换失败就卡在测量模式 → 播放没声音。
    private func activatePlaybackSession() {
        AudioSessionCoordinator.activateShared()
    }
}

// MARK: - Delegates

extension SpeechSpeaker: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in self?.isSpeaking = false }
    }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in self?.isSpeaking = false }
    }
}

extension SpeechSpeaker: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in self?.isSpeaking = false }
    }
}
