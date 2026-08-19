import SwiftUI

struct EventCardView: View {
    let event: EventDto

    @Environment(\.openURL) private var openURL
    @State private var showAddToCalendarSheet = false
    @State private var calendarStatusMessage: String?
    @State private var isGoing: Bool

    init(event: EventDto) {
        self.event = event
        _isGoing = State(initialValue: RsvpStore.isGoing(event.id))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.kofc(16, weight: .semibold))
                    .foregroundColor(KofcColors.onSurface)
                    .padding(.trailing, 28)

                Text(dateLine)
                    .font(.kofc(13, weight: .medium))
                    .foregroundColor(KofcColors.goldMuted)

                if let location = event.location, !location.isEmpty {
                    Text("📍 \(location)")
                        .font(.kofc(13))
                        .underline()
                        .foregroundColor(KofcColors.locationText)
                        .onTapGesture { openInMaps(location) }
                }

                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.kofc(14))
                        .foregroundColor(KofcColors.onSurfaceVariant)
                }

                HStack(spacing: 8) {
                    // At most one of these ever shows -- mutually exclusive by
                    // construction in KofcRepository.
                    if let signupUrl = event.signupUrl, let url = URL(string: signupUrl) {
                        actionButton(title: "Sign Up to Volunteer →", url: url)
                    } else if let linkUrl = event.linkUrl, let url = URL(string: linkUrl) {
                        actionButton(title: "Open Link →", url: url)
                    }

                    addToCalendarButton
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)

            // A corner marker, not another action button -- keeps it from
            // reading as a second "sign up" CTA next to the real one.
            interestedButton
                .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KofcColors.surface)
        .cornerRadius(8)
        // A sheet for the time-slot input step, and a separate alert for
        // the result -- keeping input and result on different presentation
        // types avoids the clobbering SwiftUI can do when two .alert()s
        // are chained on the same view.
        .sheet(isPresented: $showAddToCalendarSheet) {
            AddToCalendarSheet(
                event: event,
                onAdd: { slotTime in
                    showAddToCalendarSheet = false
                    Task {
                        switch await CalendarExporter.addToCalendar(event, slotTime: slotTime) {
                        case .added:
                            calendarStatusMessage = "Added to your calendar."
                        case .denied:
                            calendarStatusMessage = "Calendar access denied. Enable it in Settings to add events."
                        case .failed:
                            calendarStatusMessage = "Couldn't add this event to your calendar."
                        }
                    }
                },
                onCancel: { showAddToCalendarSheet = false }
            )
        }
        .alert(
            "Add to Calendar",
            isPresented: Binding(
                get: { calendarStatusMessage != nil },
                set: { if !$0 { calendarStatusMessage = nil } }
            )
        ) {
            Button("OK") { calendarStatusMessage = nil }
        } message: {
            Text(calendarStatusMessage ?? "")
        }
    }

    private var interestedButton: some View {
        Button {
            isGoing.toggle()
            RsvpStore.toggle(event.id)
        } label: {
            Image(systemName: isGoing ? "star.fill" : "star")
                .foregroundColor(isGoing ? KofcColors.gold : KofcColors.locationText)
        }
        .accessibilityLabel(isGoing ? "Marked as signed up" : "Mark as signed up")
    }

    private var addToCalendarButton: some View {
        Button {
            showAddToCalendarSheet = true
        } label: {
            Image(systemName: "calendar.badge.plus")
                .foregroundColor(KofcColors.gold)
                .padding(10)
                .background(KofcColors.navy)
                .cornerRadius(8)
        }
        .padding(.top, 4)
    }

    private var dateLine: String {
        var line = "📅 " + EventDateFormatter.displayString(from: event.date)
        if let time = event.time, !time.isEmpty {
            line += " · \(time)"
        }
        return line
    }

    private func openInMaps(_ location: String) {
        guard let encoded = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://maps.apple.com/?q=\(encoded)") else { return }
        openURL(url)
    }

    private func actionButton(title: String, url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            Text(title)
                .foregroundColor(KofcColors.gold)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(KofcColors.navy)
                .cornerRadius(8)
        }
        .padding(.top, 4)
    }
}

/// SignUpGenius events often offer several time slots (e.g. setup, serving,
/// cleanup) that the underlying Google Calendar entry has no way to
/// represent -- it only ever carries one time. Rather than guess, this asks
/// which slot the user actually signed up for before writing the calendar
/// entry.
private struct AddToCalendarSheet: View {
    let event: EventDto
    let onAdd: (Date) -> Void
    let onCancel: () -> Void

    @State private var selectedTime: Date

    init(event: EventDto, onAdd: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        self.event = event
        self.onAdd = onAdd
        self.onCancel = onCancel
        _selectedTime = State(initialValue: Self.defaultTime(for: event))
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    private static func defaultTime(for event: EventDto) -> Date {
        if let time = event.time, !time.isEmpty, let parsed = timeFormatter.date(from: time) {
            return parsed
        }
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(event.title)
                    .font(.kofc(17, weight: .semibold))
                    .multilineTextAlignment(.center)

                Text("If you signed up for a specific time slot, set it here so it's added to your calendar correctly.")
                    .font(.kofc(13))
                    .foregroundColor(KofcColors.locationText)
                    .multilineTextAlignment(.center)

                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                Spacer()
            }
            .padding()
            .navigationTitle("Add to Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { onAdd(selectedTime) }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct RsvpLegendView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
            Text("Tap the star to track events you've signed up for")
        }
        .font(.kofc(14, weight: .semibold))
        .foregroundColor(KofcColors.goldMuted)
    }
}

struct ErrorCardView: View {
    let message: String

    var body: some View {
        Text(message)
            .foregroundColor(KofcColors.errorText)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KofcColors.errorBackground)
            .cornerRadius(8)
    }
}

struct EmptyStateText: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundColor(KofcColors.emptyText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }
}
