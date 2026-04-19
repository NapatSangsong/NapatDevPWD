import Foundation

/// Loads `Secrets.plist` from the app bundle. File is **gitignored** — copy
/// `Secrets.plist.example` to `Secrets.plist`, paste your Anthropic key, and
/// re-run the build. Nothing commits to source control.
enum Secrets {
    private static var cached: [String: Any]? = {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }
        return plist
    }()

    private static func string(_ key: String) -> String? {
        let value = cached?[key] as? String
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false && trimmed?.contains("PASTE") == false) ? trimmed : nil
    }

    static var anthropicAPIKey: String? { string("anthropic_api_key") }
    static var supabaseURL: String? { string("supabase_url") }
    static var supabasePublishableKey: String? { string("supabase_publishable_key") }
}
