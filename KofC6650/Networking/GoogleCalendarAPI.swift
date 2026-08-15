import Foundation

enum GoogleCalendarAPI {
    // Public, read-only-restricted key -- the same one embedded in the
    // council's own public volunteer-signup.html widget. Safe to ship
    // client-side.
    private static let calendarId = "3j9ina0035sbq5u2f7s4oafua4@group.calendar.google.com"
    private static let apiKey = "AIzaSyDMVWRq8ykzhqKCVxiavbEfLLbvaIdahfU"

    static func fetchEvents() async throws -> [CalendarEventDto] {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let timeMin = isoFormatter.string(from: Date())

        var components = URLComponents(string: "https://www.googleapis.com")!
        components.path = "/calendar/v3/calendars/\(calendarId)/events"
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "timeMin", value: timeMin),
            // Expands recurring events into individual occurrences. An
            // earlier backend silently dropped recurring events without
            // this -- do not remove.
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "maxResults", value: "100"),
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(CalendarEventsResponse.self, from: data)
        return decoded.items
    }
}
