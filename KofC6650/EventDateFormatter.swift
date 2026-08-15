import Foundation

/// "yyyy-MM-dd" event dates are timezone-naive (Android's LocalDate).
/// Anchoring both formatters to UTC avoids the device's local timezone
/// shifting a midnight-anchored date backward/forward by a day.
enum EventDateFormatter {
    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        f.locale = Locale(identifier: "en_US")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    static func displayString(from isoDateString: String) -> String {
        guard let date = isoDateFormatter.date(from: isoDateString) else { return isoDateString }
        return displayFormatter.string(from: date)
    }

    static func isTodayOrLater(_ isoDateString: String) -> Bool {
        guard let date = isoDateFormatter.date(from: isoDateString) else { return false }
        let todayString = isoDateFormatter.string(from: Date())
        guard let today = isoDateFormatter.date(from: todayString) else { return false }
        return date >= today
    }
}
