import Foundation

/// Tracks which events the user has marked "I'm Going" to, purely locally
/// -- there's no server-side RSVP concept, this is just a personal planner.
enum RsvpStore {
    private static let key = "rsvpedEventIds"

    private static var ids: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: key) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: key) }
    }

    static func isGoing(_ eventId: String) -> Bool {
        ids.contains(eventId)
    }

    static func toggle(_ eventId: String) {
        var current = ids
        if current.contains(eventId) {
            current.remove(eventId)
        } else {
            current.insert(eventId)
        }
        ids = current
    }
}
