import Foundation

/// The one piece of state handed off from the main app to the widget
/// extension -- deliberately tiny, since it's all the widget needs to
/// render "what's next." Written by the app whenever events refresh,
/// read by the widget's timeline provider.
struct NextEventInfo: Codable {
    let title: String
    let dateDisplay: String
    let time: String?
    let location: String?

    private static let appGroupId = "group.com.erdman.kofc6650"
    private static let key = "nextEventInfo"

    static func save(_ info: NextEventInfo?) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
        guard let info else {
            defaults.removeObject(forKey: key)
            return
        }
        guard let data = try? JSONEncoder().encode(info) else { return }
        defaults.set(data, forKey: key)
    }

    static func load() -> NextEventInfo? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(NextEventInfo.self, from: data)
    }
}
