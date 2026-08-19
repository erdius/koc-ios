import SwiftUI

struct EventCardView: View {
    let event: EventDto

    @Environment(\.openURL) private var openURL
    @State private var showAddToCalendarConfirm = false
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
                        .foregroundColor(KofcColors.locationText)
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
        // A single .alert() covering both steps -- confirm, then result --
        // since SwiftUI can clobber one alert with another when two are
        // chained on the same view, which silently dropped the confirm step.
        .alert(
            "Add to Calendar",
            isPresented: Binding(
                get: { showAddToCalendarConfirm || calendarStatusMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        showAddToCalendarConfirm = false
                        calendarStatusMessage = nil
                    }
                }
            )
        ) {
            if showAddToCalendarConfirm {
                Button("Cancel", role: .cancel) { showAddToCalendarConfirm = false }
                Button("Add") {
                    showAddToCalendarConfirm = false
                    Task {
                        switch await CalendarExporter.addToCalendar(event) {
                        case .added:
                            calendarStatusMessage = "Added to your calendar."
                        case .denied:
                            calendarStatusMessage = "Calendar access denied. Enable it in Settings to add events."
                        case .failed:
                            calendarStatusMessage = "Couldn't add this event to your calendar."
                        }
                    }
                }
            } else {
                Button("OK") { calendarStatusMessage = nil }
            }
        } message: {
            Text(showAddToCalendarConfirm ? "Add \"\(event.title)\" to your calendar?" : (calendarStatusMessage ?? ""))
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
            showAddToCalendarConfirm = true
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
