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

    /// UTC-anchored, matching isoDateFormatter -- for round-tripping a
    /// Date (e.g. from calendar grid math) back to the "yyyy-MM-dd" form
    /// event.date is stored in.
    static func dateString(from date: Date) -> String {
        isoDateFormatter.string(from: date)
    }

    static func date(from isoDateString: String) -> Date? {
        isoDateFormatter.date(from: isoDateString)
    }

    static func isTodayOrLater(_ isoDateString: String) -> Bool {
        guard let date = isoDateFormatter.date(from: isoDateString) else { return false }
        let todayString = isoDateFormatter.string(from: Date())
        guard let today = isoDateFormatter.date(from: todayString) else { return false }
        return date >= today
    }

    enum DateBucket: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case later = "Later"
    }

    /// Assumes isoDateString is already today-or-later; callers filter with
    /// isTodayOrLater(_:) first.
    static func bucket(for isoDateString: String) -> DateBucket {
        guard let date = isoDateFormatter.date(from: isoDateString) else { return .later }
        let todayString = isoDateFormatter.string(from: Date())
        guard let today = isoDateFormatter.date(from: todayString) else { return .later }
        let days = Calendar(identifier: .gregorian).dateComponents([.day], from: today, to: date).day ?? 0
        if days == 0 { return .today }
        if days <= 6 { return .thisWeek }
        return .later
    }
}
