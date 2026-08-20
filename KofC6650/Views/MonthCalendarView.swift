import SwiftUI

/// A month grid with a dot under any date that has an event, plus a list of
/// the selected date's events below (reusing EventCardView so an individual
/// event looks identical to the agenda view). `events` should already be
/// filtered to today-or-later, same as the agenda views -- the backend only
/// ever returns upcoming events, so browsing to an earlier month than the
/// current one would just show an empty grid, hence the disabled "back"
/// button when already on the current month.
struct MonthCalendarView: View {
    let events: [EventDto]

    @State private var displayedMonth: Date
    @State private var selectedDateString: String

    init(events: [EventDto]) {
        self.events = events
        _displayedMonth = State(initialValue: Self.startOfMonth(Date()))
        _selectedDateString = State(initialValue: EventDateFormatter.dateString(from: Date()))
    }

    private static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private static func startOfMonth(_ date: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }

    private var isCurrentMonth: Bool {
        Self.calendar.isDate(displayedMonth, equalTo: Self.startOfMonth(Date()), toGranularity: .month)
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.timeZone = Self.calendar.timeZone
        f.locale = Locale(identifier: "en_US")
        return f.string(from: displayedMonth)
    }

    /// 42 cells (6 weeks) so the grid height never jumps between months;
    /// nil marks padding before day 1 or after the month's last day.
    private var gridDays: [Date?] {
        let cal = Self.calendar
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let firstWeekday = cal.component(.weekday, from: displayedMonth) // 1 = Sunday
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: displayedMonth) {
                days.append(date)
            }
        }
        while days.count < 42 { days.append(nil) }
        return days
    }

    private var eventDateStrings: Set<String> {
        Set(events.map { $0.date })
    }

    private var selectedDayEvents: [EventDto] {
        events
            .filter { $0.date == selectedDateString }
            .sorted { ($0.time ?? "") < ($1.time ?? "") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 12) {
                monthHeader
                weekdayRow
                dayGrid
            }
            .padding(12)
            .background(KofcColors.surface)
            .cornerRadius(8)

            selectedDayList
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(isCurrentMonth)
            .opacity(isCurrentMonth ? 0.3 : 1)

            Spacer()
            Text(monthTitle)
                .font(.kofc(17, weight: .semibold))
                .foregroundColor(KofcColors.onBackground)
            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }

            Button("Today") {
                displayedMonth = Self.startOfMonth(Date())
                selectedDateString = EventDateFormatter.dateString(from: Date())
            }
            .font(.kofc(13, weight: .semibold))
            .padding(.leading, 12)
        }
        .foregroundColor(KofcColors.navy)
    }

    private var weekdayRow: some View {
        HStack {
            ForEach(Array(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"].enumerated()), id: \.offset) { _, d in
                Text(d)
                    .font(.kofc(11, weight: .semibold))
                    .foregroundColor(KofcColors.goldMuted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 3) {
            ForEach(Array(gridDays.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let dateString = EventDateFormatter.dateString(from: date)
        let dayNumber = Self.calendar.component(.day, from: date)
        let hasEvent = eventDateStrings.contains(dateString)
        let isSelected = dateString == selectedDateString
        let isToday = dateString == EventDateFormatter.dateString(from: Date())

        return Button {
            selectedDateString = dateString
        } label: {
            VStack(spacing: 2) {
                Text("\(dayNumber)")
                    .font(.kofc(14, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? KofcColors.navy : KofcColors.onBackground)
                Circle()
                    .fill(hasEvent ? (isSelected ? KofcColors.navy : KofcColors.gold) : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(isSelected ? KofcColors.gold : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday && !isSelected ? KofcColors.gold : Color.clear, lineWidth: 1.5)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var selectedDayList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(EventDateFormatter.displayString(from: selectedDateString))
                .font(.kofc(15, weight: .semibold))
                .foregroundColor(KofcColors.onBackground)

            if selectedDayEvents.isEmpty {
                EmptyStateText(text: "No events this day.")
            } else {
                ForEach(selectedDayEvents) { event in
                    EventCardView(event: event)
                }
            }
        }
    }

    private func changeMonth(by delta: Int) {
        if let newMonth = Self.calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}
