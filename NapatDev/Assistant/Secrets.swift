import Foundation

/// Loads `Secrets.plist` from the app bundle. File is **gitignored** — copy
/// `Secrets.plist.example` to `Secrets.plist`, paste your Anthropic key, and
/// re-run the build. Nothing commits to source control.
enum Secrets {
    static var anthropicAPIKey: String? {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }
        let value = plist["anthropic_api_key"] as? String
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }
}
