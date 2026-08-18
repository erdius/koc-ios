import SwiftUI

struct CalendarTabView: View {
    let events: [EventDto]
    let isLoading: Bool
    let errorMessage: String?

    private var upcoming: [EventDto] {
        events.filter { EventDateFormatter.isTodayOrLater($0.date) }
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
                        Text("Sign ups for Upcoming Volunteer Opportunities")
                            .font(.kofc(18, weight: .semibold))
                            .foregroundColor(KofcColors.onBackground)

                        CreateSignUpLinkView()

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

private struct CreateSignUpLinkView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        (
            Text("Click here").underline().foregroundColor(KofcColors.gold)
                + Text(" to create a new sign-up").foregroundColor(KofcColors.onBackground)
        )
        .font(.kofc(17))
        .onTapGesture {
            if let url = URL(string: "https://www.signupgenius.com/") {
                openURL(url)
            }
        }
    }
}
