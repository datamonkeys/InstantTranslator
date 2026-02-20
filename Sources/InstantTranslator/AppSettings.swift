import Foundation

class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let targetLanguage = "targetLanguage"
    }

    var targetLanguage: String {
        get { defaults.string(forKey: Keys.targetLanguage) ?? "English" }
        set { defaults.set(newValue, forKey: Keys.targetLanguage) }
    }
}
