import SwiftUI

// Typography mirror of the web design: PingFang for zh, Instrument Serif
// for hero English lines, SF Pro for everything else. Instrument Serif is
// a custom font we bundle (see Resources/Fonts). Falls back to system
// serif if the font file is missing in a build.

enum AppFont {
    // Chinese + UI sans — system does the right thing on iOS with PingFang.
    static func zh(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    // Hero English practice lines. System `.serif` design = New York on iOS,
    // which is close enough to Instrument Serif for v0.1 without bundling a
    // custom font. Swap in Instrument Serif during P2 polish if the team
    // wants the exact web-version look.
    static func enSerif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    // Numbers + ALL-CAPS labels + secondary UI text.
    static func enSans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func mono(size: CGFloat) -> Font {
        .system(size: size, design: .monospaced)
    }
}
