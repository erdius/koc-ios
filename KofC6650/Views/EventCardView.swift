import SwiftUI

struct EventCardView: View {
    let event: EventDto

    @Environment(\.openURL) private var openURL
    @State private var calendarStatusMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.kofc(16, weight: .semibold))
                .foregroundColor(KofcColors.onSurface)

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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KofcColors.surface)
        .cornerRadius(8)
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

    private var addToCalendarButton: some View {
        Button {
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
