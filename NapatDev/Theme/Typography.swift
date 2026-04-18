import SwiftUI

enum Typography {
    // Falls back to system fonts if Instrument Sans / JetBrains Mono aren't bundled.
    static let sans = "InstrumentSans"
    static let sansBold = "InstrumentSans-Bold"
    static let sansSemibold = "InstrumentSans-SemiBold"
    static let sansMedium = "InstrumentSans-Medium"
    static let mono = "JetBrainsMono"

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = sansBold
        case .semibold: name = sansSemibold
        case .medium: name = sansMedium
        default: name = sans
        }
        return .custom(name, size: size, relativeTo: .body).weight(weight)
    }

    static func monospaced(_ size: CGFloat) -> Font {
        .custom(mono, size: size, relativeTo: .body)
    }
}

extension Font {
    static func nd(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Typography.sans(size, weight: weight)
    }

    static func ndMono(_ size: CGFloat) -> Font {
        Typography.monospaced(size)
    }
}
