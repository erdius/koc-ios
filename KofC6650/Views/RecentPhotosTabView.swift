import SwiftUI

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

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(KofcColors.navy)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(selectedMonth?.label ?? "Recent Photos")
                                .font(.kofc(18, weight: .semibold))
                                .foregroundColor(KofcColors.onBackground)

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

                        if displayedErrorMessage == nil && !displayedIsLoading && displayedPhotos.isEmpty {
                            EmptyStateText(text: viewingArchive ? "No photos for this month." : "No photos yet.")
                        }

                        ForEach(displayedPhotos) { photo in
                            AsyncImage(url: URL(string: photo.imageUrl)) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView().frame(height: 120)
                            }
                            .frame(maxWidth: .infinity)
                            .background(KofcColors.surface)
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture { enlargedPhoto = photo }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(KofcColors.background)
        .fullScreenCover(item: $enlargedPhoto) { photo in
            PhotoViewer(url: URL(string: photo.imageUrl)) {
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
