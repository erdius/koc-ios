import SwiftUI

struct CalendarTabView: View {
    let events: [EventDto]
    let isLoading: Bool
    let errorMessage: String?
    let onRefresh: () async -> Void

    @ObservedObject private var viewMode = CalendarViewMode.shared
    @State private var headerHeight: CGFloat = 0

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
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            headerSection
                                .id("header")
                                .measureHeight(into: $headerHeight)

                            if let errorMessage {
                                ErrorCardView(message: errorMessage)
                            }

                            if viewMode.mode == .month {
                                MonthCalendarView(events: upcoming)
                                    .id("grid")
                                // Guarantees just enough scrollable room for
                                // the auto-scroll-to-grid effect to fully
                                // push the header out of view even when the
                                // selected day's event list is short --
                                // sized to the header's own measured height
                                // rather than a full screen, so there's no
                                // dead space to keep scrolling past.
                                Color.clear.frame(height: headerHeight)
                            } else {
                                if errorMessage == nil && upcoming.isEmpty {
                                    EmptyStateText(text: "No upcoming events on the calendar.")
                                }

                                EventListSections(events: upcoming)
                            }
                        }
                        .padding(16)
                    }
                    .refreshable { await onRefresh() }
                    .onChange(of: viewMode.mode) { newMode in
                        if newMode == .month {
                            withAnimation {
                                proxy.scrollTo("grid", anchor: .top)
                            }
                        }
                    }
                    .onChange(of: headerHeight) { _ in
                        if viewMode.mode == .month {
                            proxy.scrollTo("grid", anchor: .top)
                        }
                    }
                    .onAppear {
                        if viewMode.mode == .month {
                            proxy.scrollTo("grid", anchor: .top)
                        }
                    }
                }
            }
        }
        .background(KofcColors.background)
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Volunteer Opportunities")
                .font(.kofcFixed(18, weight: .semibold))
                .foregroundColor(KofcColors.onBackground)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            CalendarViewModeToggle()

            RsvpLegendView()
        }
    }
}
