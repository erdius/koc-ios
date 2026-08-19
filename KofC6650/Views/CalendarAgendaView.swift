import SwiftUI

struct CalendarAgendaView: View {
    let events: [EventDto]
    let isLoading: Bool
    let errorMessage: String?

    private var upcoming: [EventDto] {
        events
            .filter { EventDateFormatter.isTodayOrLater($0.date) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(KofcColors.navy)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Events")
                            .font(.kofc(18, weight: .semibold))
                            .foregroundColor(KofcColors.onBackground)

                        RsvpLegendView()

                        if let errorMessage {
                            ErrorCardView(message: errorMessage)
                        }

                        if errorMessage == nil && upcoming.isEmpty {
                            EmptyStateText(text: "No upcoming events on the calendar.")
                        }

                        ForEach(upcoming) { event in
                            EventCardView(event: event)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(KofcColors.background)
    }
}
