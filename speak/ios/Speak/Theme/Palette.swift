import SwiftUI

// 配色单一源 · 对齐「每日外刊精读」外刊品牌：暖米纸张 + 陶土橙(口语识别色) +
// 金 gold + 墨绿 good。浅色 cream / 深色 dusk(暖墨夜读)。

struct Palette {
    let key: String
    let name: String
    let bg: Color
    let surface: Color
    let surfaceAlt: Color
    let ink: Color
    let inkSoft: Color
    let inkMuted: Color
    let line: Color
    let accent: Color
    let accentSoft: Color
    let accentDeep: Color
    let sage: Color
    let sageSoft: Color
    let sun: Color
    let sunSoft: Color
    let danger: Color
    let potFill: Color
    // 剑桥分区识别色(墨蓝):进剑桥后关键控件用 cam 代替 accent,与日常陶土橙分家
    let cam: Color
    let camDeep: Color
    let camSoft: Color
    let isDark: Bool
}

// hex → Color 便利构造（与 H5 的 CSS 变量同值）
extension Color {
    init(hex: String, opacity: Double = 1) {
        var s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(.sRGB,
                  red: Double((v >> 16) & 0xff) / 255,
                  green: Double((v >> 8) & 0xff) / 255,
                  blue: Double(v & 0xff) / 255,
                  opacity: opacity)
    }
}

extension Palette {
    // 外刊品牌 · 浅色
    static let cream = Palette(
        key: "cream", name: "白天",
        bg:         Color(hex: "ece6d9"),   // --paper
        surface:    Color(hex: "fcfaf4"),   // --surface
        surfaceAlt: Color(hex: "f2ede2"),   // --surface-soft
        ink:        Color(hex: "1c2b33"),   // --ink
        inkSoft:    Color(hex: "45555e"),   // --ink-soft
        inkMuted:   Color(hex: "8a8273"),   // --muted
        line:       Color(hex: "e5ddce"),   // --hairline
        accent:     Color(hex: "b06440"),   // --primary 陶土橙
        accentSoft: Color(hex: "f3e9e1"),   // --primary-soft
        accentDeep: Color(hex: "8c4c2c"),   // --primary-2
        sage:       Color(hex: "2e7d5b"),   // --good
        sageSoft:   Color(hex: "dfe9e1"),   // --good-soft
        sun:        Color(hex: "c8a24a"),   // --gold
        sunSoft:    Color(hex: "f1e7c9"),   // --gold-soft
        danger:     Color(hex: "b5562f"),   // --bad
        potFill:    Color(hex: "f2ede2"),
        cam:        Color(hex: "2f5a78"),   // --cam 墨蓝
        camDeep:    Color(hex: "1e3d54"),   // --cam-2
        camSoft:    Color(hex: "e5edf3"),   // --cam-soft
        isDark: false
    )

    // 外刊品牌 · 深色（暖墨夜读）
    static let dusk = Palette(
        key: "dusk", name: "夜晚",
        bg:         Color(hex: "15120c"),
        surface:    Color(hex: "211c14"),
        surfaceAlt: Color(hex: "2a2418"),
        ink:        Color(hex: "ece5d6"),
        inkSoft:    Color(hex: "b4ac9c"),
        inkMuted:   Color(hex: "8f8674"),
        line:       Color(hex: "332c20"),
        accent:     Color(hex: "d99a72"),
        accentSoft: Color(hex: "3a2417"),
        accentDeep: Color(hex: "8c4c2c"),
        sage:       Color(hex: "57b389"),
        sageSoft:   Color(hex: "1f3329"),
        sun:        Color(hex: "d4b264"),
        sunSoft:    Color(hex: "38301c"),
        danger:     Color(hex: "df8059"),
        potFill:    Color(hex: "2a2418"),
        cam:        Color(hex: "7fb0d0"),   // --cam 墨蓝(深色版提亮)
        camDeep:    Color(hex: "284a61"),
        camSoft:    Color(hex: "1b2c3a"),
        isDark: true
    )
}
