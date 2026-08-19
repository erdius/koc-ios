import Foundation

/// Ported line-for-line from the Android app's KofcRepository.kt. The order
/// of operations in cleanDescription and the two-step signup/generic URL
/// extraction are load-bearing -- see the Android source's comments for why
/// (SignUpGenius links become a "Sign Up" button, other links like Zoom
/// become an "Open Link" button, and every bare URL is stripped from the
/// visible description text either way so it isn't shown twice).
enum KofcRepository {
    private static let signupURLRegex = try! NSRegularExpression(
        pattern: #"https?://(?:www\.)?signupgenius\.com/[^\s<>"']*"#,
        options: [.caseInsensitive]
    )
    private static let bareURLRegex = try! NSRegularExpression(pattern: #"https?://\S+"#)
    private static let brTagRegex = try! NSRegularExpression(
        pattern: #"<br\s*/?>"#,
        options: [.caseInsensitive]
    )
    private static let htmlTagRegex = try! NSRegularExpression(pattern: #"<[^>]+>"#)
    private static let extraBlankLinesRegex = try! NSRegularExpression(pattern: #"\n{3,}"#)

    /// Fetches once and derives both signupEvents (subset) and allEvents
    /// from the same call -- the two calendar tabs used to each hit the API
    /// separately; this merges them into one round trip.
    static func getCouncilEvents() async throws -> CouncilEvents {
        let all = try await fetchEvents()
        let signupEvents = all.filter { !($0.signupUrl?.isEmpty ?? true) }
        return CouncilEvents(signupEvents: signupEvents, allEvents: all)
    }

    private static func fetchEvents() async throws -> [EventDto] {
        let raw = try await GoogleCalendarAPI.fetchEvents()
        return raw
            .filter { $0.status != "cancelled" }
            .compactMap(toEventDto)
    }

    private static func toEventDto(_ event: CalendarEventDto) -> EventDto? {
        guard let start = event.start else { return nil }

        let date: String
        if let d = start.date {
            date = d
        } else if let dateTime = start.dateTime, let tIndex = dateTime.firstIndex(of: "T") {
            date = String(dateTime[..<tIndex])
        } else {
            return nil
        }

        let time = start.dateTime.map(formatTime) ?? ""
        let title = event.summary ?? "Untitled"
        let signupUrl = extractSignupUrl(event.description)
        let linkUrl = signupUrl == nil ? extractGenericUrl(event.description) : nil

        return EventDto(
            id: event.id,
            title: title,
            date: date,
            time: time,
            location: event.location,
            description: cleanDescription(event.description),
            signupUrl: signupUrl,
            linkUrl: linkUrl
        )
    }

    /// Extracts "h:mm a" (e.g. "6:00 PM") directly from the ISO-8601
    /// dateTime's own HH:mm, matching Java's OffsetDateTime.format
    /// behavior of using the offset embedded in the string rather than
    /// converting to the device's local timezone.
    private static func formatTime(_ dateTimeString: String) -> String {
        guard let tRange = dateTimeString.range(of: "T") else { return "" }
        let afterT = dateTimeString[tRange.upperBound...]
        let parts = afterT.split(separator: ":")
        guard parts.count >= 2, let hour24 = Int(parts[0]), let minute = Int(parts[1].prefix(2)) else {
            return ""
        }
        let period = hour24 < 12 ? "AM" : "PM"
        var hour12 = hour24 % 12
        if hour12 == 0 { hour12 = 12 }
        return String(format: "%d:%02d %@", hour12, minute, period)
    }

    private static func extractSignupUrl(_ text: String?) -> String? {
        guard let text, !text.isEmpty else { return nil }
        return firstMatch(of: signupURLRegex, in: text).map(unescapeHtmlEntities)
    }

    private static func extractGenericUrl(_ text: String?) -> String? {
        guard let text, !text.isEmpty else { return nil }
        guard var url = firstMatch(of: bareURLRegex, in: text) else { return nil }
        while let last = url.last, ".,)]".contains(last) {
            url.removeLast()
        }
        return unescapeHtmlEntities(url)
    }

    // URLs are extracted from the raw (still-HTML) description, which
    // encodes multi-param query strings as "...&amp;startdate=..." --
    // opening that literally sends "amp;startdate" as the param name,
    // silently breaking any link with more than one query parameter.
    private static func unescapeHtmlEntities(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }

    private static func cleanDescription(_ text: String?) -> String {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        var result = text
        result = replaceAll(brTagRegex, in: result, with: "\n")
        result = replaceAll(htmlTagRegex, in: result, with: "")
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "\\n", with: "\n")
        result = replaceAll(bareURLRegex, in: result, with: "")
        result = replaceAll(extraBlankLinesRegex, in: result, with: "\n\n")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstMatch(of regex: NSRegularExpression, in text: String) -> String? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range), let matchRange = Range(match.range, in: text) else {
            return nil
        }
        return String(text[matchRange])
    }

    private static func replaceAll(_ regex: NSRegularExpression, in text: String, with replacement: String) -> String {
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
    }
}
