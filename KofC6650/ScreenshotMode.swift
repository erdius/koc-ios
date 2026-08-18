import Foundation

/// Activated only via the `-ScreenshotMode` launch argument (see
/// KofC6650ScreenshotUITests), never in a real launch. Swaps live council
/// data for generic placeholders so App Store screenshots don't expose
/// real event locations or real photos of real people.
enum ScreenshotMode {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-ScreenshotMode")
    }

    private static let placeholderDescription =
        "This is a placeholder description for a sample community event. Real event " +
        "details, dates, and locations appear here in the app — removed from this " +
        "screenshot for privacy."

    /// A real, valid future date (today + `daysAhead`) formatted as "yyyy-MM-dd" --
    /// CalendarTabView filters out anything that fails EventDateFormatter's parser,
    /// so the placeholder dates can't be non-parsing text like "Month 00, 2026".
    private static func futureDate(daysAhead: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: daysAhead, to: Date()) ?? Date()
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: date)
    }

    static let sampleSignupEvents: [EventDto] = [
        EventDto(
            id: "sample-signup-1", title: "Sample Volunteer Event",
            date: futureDate(daysAhead: 7), time: nil, location: nil, description: nil,
            signupUrl: "https://www.signupgenius.com/", linkUrl: nil
        ),
        EventDto(
            id: "sample-signup-2", title: "Another Volunteer Opportunity",
            date: futureDate(daysAhead: 14), time: nil, location: nil, description: nil,
            signupUrl: "https://www.signupgenius.com/", linkUrl: nil
        ),
        EventDto(
            id: "sample-signup-3", title: "Community Outreach Event",
            date: futureDate(daysAhead: 21), time: nil, location: nil, description: nil,
            signupUrl: nil, linkUrl: nil
        ),
    ]

    static let sampleAllEvents: [EventDto] = [
        EventDto(
            id: "sample-cal-1", title: "Sample Community Event",
            date: futureDate(daysAhead: 4), time: "6:00 PM", location: nil,
            description: placeholderDescription,
            signupUrl: "https://www.signupgenius.com/", linkUrl: nil
        ),
        EventDto(
            id: "sample-cal-2", title: "Sample Community Event",
            date: futureDate(daysAhead: 9), time: "6:00 PM", location: nil, description: nil,
            signupUrl: nil, linkUrl: nil
        ),
    ]
}
