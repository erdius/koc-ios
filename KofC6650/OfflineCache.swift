import Foundation

/// Persists the last successful fetch of events/photos so a network failure
/// shows the user's last-known data instead of a dead-end error card. Not a
/// general-purpose cache -- just enough to keep the app useful when offline.
enum OfflineCache {
    private static let signupEventsKey = "offline_signupEvents"
    private static let allEventsKey = "offline_allEvents"
    private static let recentPhotosKey = "offline_recentPhotos"
    private static let eventsSavedAtKey = "offline_eventsSavedAt"
    private static let photosSavedAtKey = "offline_photosSavedAt"

    static func saveEvents(_ council: CouncilEvents) {
        save(council.signupEvents, forKey: signupEventsKey)
        save(council.allEvents, forKey: allEventsKey)
        UserDefaults.standard.set(Date(), forKey: eventsSavedAtKey)
    }

    static func loadEvents() -> CouncilEvents? {
        guard
            let signup: [EventDto] = load(forKey: signupEventsKey),
            let all: [EventDto] = load(forKey: allEventsKey)
        else { return nil }
        return CouncilEvents(signupEvents: signup, allEvents: all)
    }

    static func savePhotos(_ photos: [RecentPhotoDto]) {
        save(photos, forKey: recentPhotosKey)
        UserDefaults.standard.set(Date(), forKey: photosSavedAtKey)
    }

    static func loadPhotos() -> [RecentPhotoDto]? {
        load(forKey: recentPhotosKey)
    }

    static var eventsSavedAt: Date? {
        UserDefaults.standard.object(forKey: eventsSavedAtKey) as? Date
    }

    static var photosSavedAt: Date? {
        UserDefaults.standard.object(forKey: photosSavedAtKey) as? Date
    }

    private static func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func load<T: Decodable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
