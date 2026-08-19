import SwiftUI
import WidgetKit

@MainActor
final class AppViewModel: ObservableObject {
    @Published var signupEvents: [EventDto] = []
    @Published var allEvents: [EventDto] = []
    @Published var isLoadingEvents = true
    @Published var eventsError: String?

    @Published var recentPhotos: [RecentPhotoDto] = []
    @Published var isLoadingPhotos = true
    @Published var photosError: String?
    // Newest photo first (server returns them reverse-chronological), so
    // comparing just the first id against what was last seen is enough to
    // know whether anything new has shown up.
    @Published var hasNewPhotos = false
    private static let lastSeenPhotoIdKey = "lastSeenPhotoId"

    func markPhotosSeen() {
        guard let latest = recentPhotos.first?.id else { return }
        UserDefaults.standard.set(latest, forKey: Self.lastSeenPhotoIdKey)
        hasNewPhotos = false
    }

    private func updateHasNewPhotos() {
        guard let latest = recentPhotos.first?.id else {
            hasNewPhotos = false
            return
        }
        let lastSeen = UserDefaults.standard.string(forKey: Self.lastSeenPhotoIdKey)
        hasNewPhotos = latest != lastSeen
    }

    func refresh() async {
        if ScreenshotMode.isActive {
            signupEvents = ScreenshotMode.sampleSignupEvents
            allEvents = ScreenshotMode.sampleAllEvents
            isLoadingEvents = false
            recentPhotos = []
            isLoadingPhotos = false
            return
        }

        isLoadingEvents = true
        eventsError = nil
        isLoadingPhotos = true
        photosError = nil

        async let events: Void = loadEvents()
        async let photos: Void = loadPhotos()
        _ = await (events, photos)
    }

    private func loadEvents() async {
        do {
            let council = try await KofcRepository.getCouncilEvents()
            signupEvents = council.signupEvents
            allEvents = council.allEvents
            OfflineCache.saveEvents(council)
        } catch {
            if let cached = OfflineCache.loadEvents() {
                signupEvents = cached.signupEvents
                allEvents = cached.allEvents
                eventsError = "Showing saved events from \(Self.relativeSavedAt(OfflineCache.eventsSavedAt)) — couldn't reach the server."
            } else {
                eventsError = "Could not load calendar events."
            }
        }
        isLoadingEvents = false
        updateWidgetData()
    }

    // Hands the next upcoming event to the home screen widget via the
    // shared App Group -- the widget process can't reach the network or
    // KofcRepository itself, so this is the only way it learns anything.
    private func updateWidgetData() {
        let next = allEvents
            .filter { EventDateFormatter.isTodayOrLater($0.date) }
            .sorted { $0.date < $1.date }
            .first
        let info = next.map {
            NextEventInfo(
                title: $0.title,
                dateDisplay: EventDateFormatter.displayString(from: $0.date),
                time: ($0.time?.isEmpty == false) ? $0.time : nil,
                location: $0.location
            )
        }
        NextEventInfo.save(info)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func loadPhotos() async {
        do {
            let photos = try await PhotoAPI.fetchRecentPhotos()
            recentPhotos = photos
            OfflineCache.savePhotos(photos)
        } catch {
            if let cached = OfflineCache.loadPhotos() {
                recentPhotos = cached
                photosError = "Showing saved photos from \(Self.relativeSavedAt(OfflineCache.photosSavedAt)) — couldn't reach the server."
            } else {
                photosError = "Could not load recent photos."
            }
        }
        isLoadingPhotos = false
        updateHasNewPhotos()
    }

    private static func relativeSavedAt(_ date: Date?) -> String {
        guard let date else { return "earlier" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var pinManager = PinManager()
    // Observed here (root) so that changing it anywhere -- the About sheet
    // -- triggers a full re-render, re-evaluating every Font.kofc(...) call
    // throughout the tree with the new multiplier.
    @ObservedObject private var fontScale = FontScale.shared
    @State private var selectedTab = 0
    @Environment(\.scenePhase) private var scenePhase
    // Seeded to .active (not .background) so the very first scenePhase
    // change during cold launch never matches "returning from background"
    // below -- matches Android's DisposableEffect + isFirstResume guard,
    // which skips the Activity's first ON_RESUME so the initial .task
    // fetch isn't duplicated.
    @State private var previousScenePhase: ScenePhase = .active
    @State private var showAbout = false
    @State private var showDirectorsOfficers = false

    var body: some View {
        if !pinManager.isUnlocked {
            PinGateView(pinManager: pinManager)
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            header
            TabView(selection: $selectedTab) {
                CalendarTabView(
                    events: viewModel.signupEvents,
                    isLoading: viewModel.isLoadingEvents,
                    errorMessage: viewModel.eventsError,
                    onRefresh: { await viewModel.refresh() }
                )
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Sign Ups")
                }
                .tag(0)

                CalendarAgendaView(
                    events: viewModel.allEvents,
                    isLoading: viewModel.isLoadingEvents,
                    errorMessage: viewModel.eventsError,
                    onRefresh: { await viewModel.refresh() }
                )
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(1)

                PhotosTabView(pinManager: pinManager)
                    .tabItem {
                        Image(systemName: "camera.fill")
                        Text("Submit Photos")
                    }
                    .tag(2)

                RecentPhotosTabView(
                    photos: viewModel.recentPhotos,
                    isLoading: viewModel.isLoadingPhotos,
                    errorMessage: viewModel.photosError,
                    onRefresh: { await viewModel.refresh() }
                )
                .tabItem {
                    Image(systemName: "photo.on.rectangle.fill")
                    Text("Recent Photos")
                }
                .tag(3)
                // An empty string still renders as a dot on newer iOS tab
                // bar styles -- must be nil, not "", to actually hide it.
                .badge(viewModel.hasNewPhotos ? "•" : (nil as String?))
            }
            // Without this, a focused text field's keyboard pushes the
            // whole TabView (including the tab bar itself) up the screen
            // instead of just resizing the scrollable content above it.
            .ignoresSafeArea(.keyboard, edges: .bottom)
            // Tab content views (EventCardView, PhotosTabView, etc.) don't
            // observe FontScale themselves, so a preset change alone isn't
            // guaranteed to re-evaluate their body. Changing .id forces
            // SwiftUI to discard and rebuild the whole subtree fresh.
            .id(fontScale.preset)
        }
        .task {
            await viewModel.refresh()
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == 3 { viewModel.markPhotosSeen() }
        }
        // If photos are still loading when the user first switches to this
        // tab, markPhotosSeen() above finds an empty list and no-ops -- and
        // since the tab won't change again on its own, the badge would get
        // stuck. Catches that by re-checking whenever the photo list itself
        // updates while already on this tab.
        .onChange(of: viewModel.recentPhotos) { _ in
            if selectedTab == 3 { viewModel.markPhotosSeen() }
        }
        .onChange(of: scenePhase) { newPhase in
            defer { previousScenePhase = newPhase }
            if previousScenePhase == .background && newPhase == .active {
                Task { await viewModel.refresh() }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(KofcColors.gold).frame(width: 44, height: 44)
                Text("K").font(.kofc(20, weight: .bold)).foregroundColor(KofcColors.navy)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Knights of Columbus")
                    .font(.kofc(21, weight: .semibold))
                    .foregroundColor(KofcColors.gold)
                Text("Council 6650 — Cary & Apex, NC")
                    .font(.kofc(13))
                    .foregroundColor(KofcColors.subtitleText)
            }

            Spacer()

            Button {
                showDirectorsOfficers = true
            } label: {
                Image(systemName: "envelope.circle")
                    .foregroundColor(KofcColors.gold)
            }

            Button {
                showAbout = true
            } label: {
                Image(systemName: "info.circle")
                    .foregroundColor(KofcColors.gold)
            }

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(KofcColors.gold)
            }
        }
        .padding(16)
        .background(KofcColors.navy)
        .sheet(isPresented: $showAbout) {
            AboutView(pinManager: pinManager)
        }
        .sheet(isPresented: $showDirectorsOfficers) {
            DirectorsOfficersView()
        }
    }
}
