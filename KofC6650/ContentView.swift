import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var signupEvents: [EventDto] = []
    @Published var allEvents: [EventDto] = []
    @Published var isLoadingEvents = true
    @Published var eventsError: String?

    @Published var recentPhotos: [RecentPhotoDto] = []
    @Published var isLoadingPhotos = true
    @Published var photosError: String?

    func refresh() async {
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
        } catch {
            eventsError = "Could not load calendar events."
        }
        isLoadingEvents = false
    }

    private func loadPhotos() async {
        do {
            recentPhotos = try await PhotoAPI.fetchRecentPhotos()
        } catch {
            photosError = "Could not load recent photos."
        }
        isLoadingPhotos = false
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
                    errorMessage: viewModel.eventsError
                )
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Sign Ups")
                }
                .tag(0)

                CalendarAgendaView(
                    events: viewModel.allEvents,
                    isLoading: viewModel.isLoadingEvents,
                    errorMessage: viewModel.eventsError
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
                    errorMessage: viewModel.photosError
                )
                .tabItem {
                    Image(systemName: "photo.on.rectangle.fill")
                    Text("Recent Photos")
                }
                .tag(3)
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
