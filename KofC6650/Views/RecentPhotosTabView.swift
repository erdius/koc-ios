import SwiftUI

struct RecentPhotosTabView: View {
    let photos: [RecentPhotoDto]
    let isLoading: Bool
    let errorMessage: String?

    @State private var enlargedPhoto: RecentPhotoDto?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(KofcColors.navy)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Photos")
                            .font(.kofc(18, weight: .semibold))
                            .foregroundColor(KofcColors.onBackground)

                        if let errorMessage {
                            ErrorCardView(message: errorMessage)
                        }

                        if errorMessage == nil && photos.isEmpty {
                            EmptyStateText(text: "No photos yet.")
                        }

                        ForEach(photos) { photo in
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
