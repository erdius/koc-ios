import EventKit
import Foundation

/// Exports an EventDto to the device's calendar via EventKit. The API only
/// ever gives us a start time (no end), so timed events default to a 1-hour
/// block -- long enough to be useful without implying a false precision the
/// source data doesn't actually have.
enum CalendarExporter {
    enum Result {
        case added
        case denied
        case failed
    }

    private static let store = EKEventStore()

    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    static func addToCalendar(_ event: EventDto) async -> Result {
        let granted = await requestAccess()
        guard granted else { return .denied }
        return save(event)
    }

    private static func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private static func save(_ event: EventDto) -> Result {
        guard let day = isoDateFormatter.date(from: event.date) else { return .failed }

        let calendar = Calendar(identifier: .gregorian)
        let ekEvent = EKEvent(eventStore: store)
        ekEvent.title = event.title
        ekEvent.location = event.location
        ekEvent.notes = event.description
        ekEvent.calendar = store.defaultCalendarForNewEvents

        if let time = event.time, !time.isEmpty, let parsedTime = timeFormatter.date(from: time) {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: parsedTime)
            var startComponents = calendar.dateComponents([.year, .month, .day], from: day)
            startComponents.hour = timeComponents.hour
            startComponents.minute = timeComponents.minute
            guard let start = calendar.date(from: startComponents) else { return .failed }
            ekEvent.startDate = start
            ekEvent.endDate = calendar.date(byAdding: .hour, value: 1, to: start)
            ekEvent.isAllDay = false
        } else {
            ekEvent.startDate = day
            ekEvent.endDate = day
            ekEvent.isAllDay = true
        }

        do {
            try store.save(ekEvent, span: .thisEvent)
            return .added
        } catch {
            return .failed
        }
    }
}
