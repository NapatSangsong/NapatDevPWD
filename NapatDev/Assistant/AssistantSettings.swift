import Foundation
import Observation

/// User-facing Claude model choice for the assistant. Haiku is the default —
/// it's cheap, fast, and good enough at the simple tool calls this app makes.
/// Sonnet costs roughly 3× as much and is slower, but it's noticeably better
/// at nuanced multi-step reasoning when you need it.
enum AssistantModel: String, CaseIterable, Identifiable {
    case haiku = "claude-haiku-4-5"
    case sonnet = "claude-sonnet-4-6"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .haiku:  return "Haiku 4.5 (fast, cheap)"
        case .sonnet: return "Sonnet 4.6 (smarter, slower)"
        }
    }
}

@MainActor
@Observable
final class AssistantSettings {
    var model: AssistantModel {
        didSet { UserDefaults.standard.set(model.rawValue, forKey: Self.modelKey) }
    }

    private static let modelKey = "napatdev.assistantModel"

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.modelKey) ?? AssistantModel.haiku.rawValue
        self.model = AssistantModel(rawValue: raw) ?? .haiku
    }
}
