import Foundation
import AVFoundation

// 录音与示范播放共用一个 AVAudioSession —— 这里是唯一配置入口。
//
// 用户验收报的坑:先录音、再点播放示范 → 没声音。两个原因叠加:
// ① 录音把 session 设成 mode `.measurement`。该模式为「精确测量」关掉系统信号
//    处理,在真机上会显著削弱扬声器输出,于是播放近乎无声。
// ② SpeechSpeaker 切 `.playback` 时用的是 `try?`,切换失败被静默吞掉,
//    session 就一直卡在测量模式(错误连日志都没有,无从排查)。
//
// 对策:统一成一个 category `.playAndRecord` + mode `.default` + `.defaultToSpeaker`,
// 录音与播放全程不再切换 category —— 既避免测量模式掉音量,也避开来回切
// category 曾踩过的激活竞态(见 SpeechRecorder.completeStart 注释)。
// 失败一律记日志,不再静默。
//
// ⚠️ 录音输入质量:去掉 `.measurement` 后系统会介入 AGC/降噪。SOE 评测吃的是
// 16k PCM,实测这类常规处理不影响音素级评分;而「播放没声音」是用户可感的硬伤,
// 两害相权取其轻。若日后发现评分受影响,应改为「录音时才切 measurement、
// 停止录音后立刻切回 default」,而不是回到长期停在 measurement 的老样子。
enum AudioSessionCoordinator {

    /// 录音和播放共用的配置。多次调用是幂等的。
    static func activateShared() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord,
                                    mode: .default,
                                    options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            NSLog("[AudioSession] 配置失败: %@", error.localizedDescription)
        }
    }

    /// 离开录音/练习页时释放,把麦克风还给别的 App。
    static func deactivate() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            NSLog("[AudioSession] 释放失败: %@", error.localizedDescription)
        }
    }
}
