import Foundation

enum KeychainHelper {
    private static let defaults = UserDefaults.standard

    static func save(key: String, value: String) {
        defaults.set(value, forKey: key)
    }

    static func load(key: String) -> String? {
        defaults.string(forKey: key)
    }

    static func delete(key: String) {
        defaults.removeObject(forKey: key)
    }
}
