import SwiftUI
import UIKit

struct RecentPhotosTabView: View {
    let photos: [RecentPhotoDto]
    let isLoading: Bool
    let errorMessage: String?

    @State private var enlargedPhoto: RecentPhotoDto?

    // Archive browsing: nil selectedMonth means "current month" (the
    // photos/isLoading/errorMessage passed in from AppViewModel's own
    // refresh cycle). Picking a past month fetches and displays that
    // month's photos instead, without touching the caller's state.
    @State private var showMonthPicker = false
    @State private var archiveMonths: [ArchiveMonthDto] = []
    @State private var isLoadingArchiveMonths = false
    @State private var selectedMonth: ArchiveMonthDto?
    @State private var archivePhotos: [RecentPhotoDto] = []
    @State private var isLoadingArchivePhotos = false
    @State private var archiveErrorMessage: String?

    private var viewingArchive: Bool { selectedMonth != nil }
    private var displayedPhotos: [RecentPhotoDto] { viewingArchive ? archivePhotos : photos }
    private var displayedErrorMessage: String? { viewingArchive ? archiveErrorMessage : errorMessage }
    private var displayedIsLoading: Bool { viewingArchive && isLoadingArchivePhotos }

    private static let currentMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    private var currentMonthTitle: String {
        Self.currentMonthFormatter.string(from: Date())
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
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Faith in Action")
                                    .font(.kofc(14, weight: .bold))
                                    .foregroundColor(KofcColors.gold)
                                    .textCase(.uppercase)
                                    .tracking(1.2)
                                Text(selectedMonth?.label ?? currentMonthTitle)
                                    .font(.kofc(18, weight: .semibold))
                                    .foregroundColor(KofcColors.onBackground)
                            }

                            Spacer()

                            Button(viewingArchive ? "Back to Recent" : "Browse Past Months") {
                                if viewingArchive {
                                    selectedMonth = nil
                                } else {
                                    showMonthPicker = true
                                }
                            }
                            .font(.kofc(14))
                        }

                        if displayedIsLoading {
                            ProgressView()
                                .tint(KofcColors.navy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        }

                        if let displayedErrorMessage {
                            ErrorCardView(message: displayedErrorMessage)
                        }

                        if ScreenshotMode.isActive {
                            SamplePhotoPlaceholder()
                        } else if displayedErrorMessage == nil && !displayedIsLoading && displayedPhotos.isEmpty {
                            EmptyStateText(text: viewingArchive ? "No photos for this month." : "No photos yet.")
                        }

                        if !ScreenshotMode.isActive {
                            ForEach(displayedPhotos) { photo in
                                PhotoGridThumbnail(photo: photo)
                                    .contentShape(Rectangle())
                                    .onTapGesture { enlargedPhoto = photo }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(KofcColors.background)
        .fullScreenCover(item: $enlargedPhoto) { photo in
            PhotoViewer(url: URL(string: photo.mediumUrl)) {
                enlargedPhoto = nil
            }
        }
        .sheet(isPresented: $showMonthPicker) {
            MonthPickerView(
                months: archiveMonths,
                isLoading: isLoadingArchiveMonths,
                onSelect: { month in
                    selectedMonth = month
                    showMonthPicker = false
                },
                onCancel: { showMonthPicker = false }
            )
        }
        .task(id: showMonthPicker) {
            guard showMonthPicker, archiveMonths.isEmpty else { return }
            isLoadingArchiveMonths = true
            defer { isLoadingArchiveMonths = false }
            archiveMonths = (try? await PhotoAPI.fetchArchiveMonths()) ?? []
        }
        .task(id: selectedMonth) {
            guard let month = selectedMonth else { return }
            isLoadingArchivePhotos = true
            archiveErrorMessage = nil
            defer { isLoadingArchivePhotos = false }
            do {
                archivePhotos = try await PhotoAPI.fetchArchivedPhotos(month: month.month)
            } catch {
                archiveErrorMessage = "Could not load photos for this month."
            }
        }
    }
}

// Plain AsyncImage shows its placeholder forever on failure, not just
// while loading -- a single transient network hiccup on the thumbnail
// would strand the user with a permanent spinner. This retries once with
// the full-size image before giving up, and only then shows a static
// broken-image icon instead of spinning indefinitely.
// Shared across all thumbnail cells (not per-view @State) so a cell that
// gets torn down and recreated -- which LazyVStack does for boundary items
// as a scroll gesture hovers right at the content edge -- can redisplay an
// already-loaded image instantly instead of flashing back to a loading
// placeholder and re-fetching, which is what made scrolling near the last
// photo feel jittery.
private let thumbnailImageCache = NSCache<NSString, UIImage>()

private struct PhotoGridThumbnail: View {
    let photo: RecentPhotoDto
    // Real WiFi/cellular radios drop the occasional request in ways a
    // simulator's networking doesn't, and AsyncImage never retries on its
    // own. This loads the bytes manually (with retries) entirely inside
    // one @State-driven view whose identity never changes, so the list's
    // layout stays stable no matter how many retries happen.
    @State private var uiImage: UIImage?
    @State private var loadFailed = false
    private let maxAttempts = 3

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage).resizable().scaledToFit()
            } else if loadFailed {
                Image(systemName: "photo")
                    .foregroundColor(KofcColors.locationText)
                    .frame(height: 120)
            } else {
                ProgressView().frame(height: 120)
            }
        }
        .frame(maxWidth: .infinity)
        .background(KofcColors.surface)
        .cornerRadius(8)
        .task(id: photo.thumbnailUrl) {
            let key = photo.thumbnailUrl as NSString
            if let cached = thumbnailImageCache.object(forKey: key) {
                uiImage = cached
                return
            }
            await loadWithRetry()
        }
    }

    private func loadWithRetry() async {
        guard let url = URL(string: photo.thumbnailUrl) else {
            loadFailed = true
            return
        }
        for attempt in 0..<maxAttempts {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let image = UIImage(data: data) {
                thumbnailImageCache.setObject(image, forKey: photo.thumbnailUrl as NSString)
                uiImage = image
                return
            }
            if attempt < maxAttempts - 1 {
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
        }
        loadFailed = true
    }
}

private struct SamplePhotoPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera")
                .font(.system(size: 48))
                .foregroundColor(KofcColors.gold)
            Text("Sample Event Photo")
                .font(.kofc(16, weight: .semibold))
                .foregroundColor(KofcColors.gold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
        .background(KofcColors.navy)
        .cornerRadius(8)
    }
}

private struct MonthPickerView: View {
    let months: [ArchiveMonthDto]
    let isLoading: Bool
    let onSelect: (ArchiveMonthDto) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().tint(KofcColors.navy)
                } else if months.isEmpty {
                    EmptyStateText(text: "No archived photos yet.")
                } else {
                    List(months) { month in
                        Button {
                            onSelect(month)
                        } label: {
                            HStack {
                                Text(month.label).foregroundColor(KofcColors.onBackground)
                                Spacer()
                                Text("\(month.count)").foregroundColor(KofcColors.locationText)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Browse Past Months")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close", action: onCancel)
                }
            }
        }
    }
}

/// Pinch-zoom/pan viewer matching the Android Dialog's behavior: scale
/// clamped to [1, 5], pan disabled and reset whenever scale <= 1.
private struct PhotoViewer: View {
    let url: URL?
    let onClose: () -> Void

    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.9).ignoresSafeArea()

            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = min(5, max(1, value))
                            }
                            .onEnded { _ in
                                if scale <= 1 {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                guard scale > 1 else { return }
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
            } placeholder: {
                ProgressView().tint(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(8)
            }
            .padding(8)
        }
    }
}
