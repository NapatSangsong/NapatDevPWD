import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// Mirrors design/styles.css :root and html[data-theme="dark"].
enum DesignTokens {
    // MARK: - Radii (matches --radius-lg/md/sm)
    enum Radius {
        static let large: CGFloat = 18
        static let medium: CGFloat = 12
        static let small: CGFloat = 8
        static let phone: CGFloat = 44
    }

    // MARK: - Accent (cornflower)
    static let accent        = Color(light: 0x5B7CFA, dark: 0x5B7CFA)
    static let accentInk     = Color(light: 0x3D5BD9, dark: 0x8AA1FF)
    static let accentSoft    = Color(lightHex: 0xE5ECFF, dark: Color(red: 0.356, green: 0.486, blue: 0.980, opacity: 0.18))
    static let accentGlow    = Color(light: 0x5B7CFA, dark: 0x5B7CFA).opacity(0.25)

    static let good          = Color(light: 0x16A37B, dark: 0x16A37B)

    // MARK: - Inks (foreground text)
    static let ink           = Color(light: 0x14181F, dark: 0xEEF1F8)
    static let ink2          = Color(light: 0x3A4050, dark: 0xC6CDDE)
    static let muted         = Color(light: 0x6B7488, dark: 0x8892A8)
    static let muted2        = Color(light: 0x8A92A6, dark: 0x6B7488)

    // MARK: - Surfaces
    static let bg            = Color(light: 0xEEF1F6, dark: 0x0E1117)
    static let surface       = Color(light: 0xFFFFFF, dark: 0x161A22)
    static let surface2      = Color(light: 0xF7F8FA, dark: 0x1C2230)
    static let surface3      = Color(light: 0xEEF0F4, dark: 0x232A3A)

    static let hairline      = Color(lightHex: 0x0F172A, dark: Color.white).opacity(0.08)
    static let hairlineStrong = Color(lightHex: 0x0F172A, dark: Color.white).opacity(0.14)

    static let cardSolid     = Color(light: 0xFFFFFF, dark: 0x1C2230)

    static let windowGradient = LinearGradient(
        colors: [Color(light: 0xEEF1F6, dark: 0x0B0E14), Color(light: 0xE8EBF2, dark: 0x0E1118)],
        startPoint: .top, endPoint: .bottom
    )
}

extension Color {
    init(hex: Int, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    /// Dual-mode color: picks `light` hex in light mode, `dark` hex in dark mode.
    init(light: Int, dark: Int) {
        #if canImport(UIKit)
        let lightUI = UIColor(Color(hex: light))
        let darkUI  = UIColor(Color(hex: dark))
        self = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? darkUI : lightUI
        })
        #elseif canImport(AppKit)
        let lightNS = NSColor(Color(hex: light))
        let darkNS  = NSColor(Color(hex: dark))
        self = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? darkNS : lightNS
        })
        #else
        self = Color(hex: light)
        #endif
    }

    /// Dual-mode color with a custom `Color` value for dark mode (so you can
    /// pass opacity etc.).
    init(lightHex: Int, dark: Color) {
        #if canImport(UIKit)
        let darkUI = UIColor(dark)
        self = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? darkUI : UIColor(Color(hex: lightHex))
        })
        #elseif canImport(AppKit)
        let darkNS = NSColor(dark)
        self = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? darkNS
                : NSColor(Color(hex: lightHex))
        })
        #else
        self = Color(hex: lightHex)
        #endif
    }
}
