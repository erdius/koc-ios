import Foundation

// Raw Google Calendar API v3 response shapes.

struct CalendarEventsResponse: Decodable {
    let items: [CalendarEventDto]

    private enum CodingKeys: String, CodingKey { case items }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([CalendarEventDto].self, forKey: .items) ?? []
    }
}

struct CalendarEventDto: Decodable {
    let id: String
    let summary: String?
    let description: String?
    let location: String?
    let status: String?
    let start: CalendarEventDateTime?
}

struct CalendarEventDateTime: Decodable {
    let date: String?       // all-day event, e.g. "2026-08-20"
    let dateTime: String?   // timed event, e.g. "2026-08-20T18:00:00-04:00"
}

// App-level normalized model, derived by KofcRepository.

struct EventDto: Identifiable {
    let id: String
    let title: String
    let date: String        // "yyyy-MM-dd"
    let time: String?       // formatted "h:mm a", or "" if all-day
    let location: String?
    let description: String? // HTML-cleaned plain text
    let signupUrl: String?   // extracted SignUpGenius URL, or nil
    let linkUrl: String?     // extracted generic URL (e.g. Zoom), or nil; mutually exclusive with signupUrl
}

struct CouncilEvents {
    let signupEvents: [EventDto]
    let allEvents: [EventDto]
}
