import Foundation

/// Bump `version` whenever there's something worth telling users about, and
/// update `changelog` to match -- shown once via a sheet the first time the
/// app launches after updating to that version.
enum WhatsNew {
    static let version = "1.0.13"
    static let changelog = """
    • Long-press the app icon for quick access to Recent Photos and Submit Photos
    • You'll now see a short "What's New" summary like this one after updates
    """

    private static let lastSeenKey = "whatsNewLastSeenVersion"

    static var shouldShow: Bool {
        UserDefaults.standard.string(forKey: lastSeenKey) != version
    }

    static func markSeen() {
        UserDefaults.standard.set(version, forKey: lastSeenKey)
    }
}
