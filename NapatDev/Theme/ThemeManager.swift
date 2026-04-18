import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: Self { self }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}

@MainActor
@Observable
final class ThemeManager {
    var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "napatdev.theme") }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "napatdev.theme") ?? AppTheme.system.rawValue
        self.theme = AppTheme(rawValue: raw) ?? .system
    }
}
