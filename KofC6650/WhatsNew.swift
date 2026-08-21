import Foundation

/// Bump `version` whenever there's something worth telling users about, and
/// update `changelog` to match -- shown once via a sheet the first time the
/// app launches after updating to that version.
enum WhatsNew {
    static let version = "1.0.15"
    static let changelog = """
    • New Month view for the Sign Ups and Calendar tabs — toggle between Agenda and Month to browse events on a calendar grid
    • Updated contact info on the Directors & Officers page
    """

    private static let lastSeenKey = "whatsNewLastSeenVersion"

    static var shouldShow: Bool {
        UserDefaults.standard.string(forKey: lastSeenKey) != version
    }

    static func markSeen() {
        UserDefaults.standard.set(version, forKey: lastSeenKey)
    }
}
