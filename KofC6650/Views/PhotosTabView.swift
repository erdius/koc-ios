import SwiftUI
import PhotosUI

private struct SelectedImage {
    let data: Data
    let mimeType: String
    let preview: UIImage
}

struct PhotosTabView: View {
    // Not shown as a field anymore -- reaching this tab at all already
    // means PinGateView verified it at app launch. Still needed here as the
    // value actually sent with the upload request.
    let pinManager: PinManager

    @State private var name: String = ""
    @State private var caption: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [SelectedImage] = []
    @State private var isSubmitting = false
    @State private var statusMessage: String?
    @State private var statusIsError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Share Your Event Photos")
                    .font(.kofc(18, weight: .semibold))
                    .foregroundColor(KofcColors.onBackground)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Council Photo Submissions")
                        .font(.kofc(16, weight: .semibold))
                        .foregroundColor(KofcColors.onSurface)

                    Text("📷 Submit photos from council events, activities, and volunteer work")
                        .font(.kofc(13, weight: .medium))
                        .foregroundColor(KofcColors.goldMuted)

                    Text("Choose photos from your gallery and submit — no Google account needed.")
                        .font(.kofc(14))
                        .foregroundColor(KofcColors.helpText)

                    TextField("Your name (optional)", text: $name)
                        .textFieldStyle(.roundedBorder)

                    TextField("Caption (optional)", text: $caption)
                        .textFieldStyle(.roundedBorder)

                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 20,
                        matching: .images
                    ) {
                        Text(pickerLabel)
                            .foregroundColor(KofcColors.gold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(KofcColors.navy)
                            .cornerRadius(8)
                    }
                    .onChange(of: selectedItems) { newItems in
                        Task { await loadSelectedImages(newItems) }
                    }

                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { _, image in
                                    Image(uiImage: image.preview)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .clipped()
                                }
                            }
                        }
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(KofcColors.gold)
                                    .scaleEffect(0.7)
                            } else {
                                Text("Submit")
                            }
                        }
                        .foregroundColor(KofcColors.gold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(KofcColors.navy)
                        .cornerRadius(8)
                    }
                    .disabled(isSubmitting)

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.kofc(13))
                            .foregroundColor(statusIsError ? KofcColors.uploadError : KofcColors.uploadSuccess)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KofcColors.surface)
                .cornerRadius(8)
            }
            .padding(16)
        }
        .background(KofcColors.background)
        .keyboardDoneButton()
    }

    private var pickerLabel: String {
        selectedImages.isEmpty
            ? "Choose Photos from Gallery"
            : "\(selectedImages.count) photo\(selectedImages.count == 1 ? "" : "s") selected — change"
    }

    private func loadSelectedImages(_ items: [PhotosPickerItem]) async {
        var results: [SelectedImage] = []
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            guard let uiImage = UIImage(data: data) else { continue }
            let mimeType = item.supportedContentTypes.first?.preferredMIMEType ?? "image/jpeg"
            results.append(SelectedImage(data: data, mimeType: mimeType, preview: uiImage))
        }
        selectedImages = results
    }

    private func submit() async {
        guard !selectedImages.isEmpty else {
            statusIsError = true
            statusMessage = "Choose at least one photo"
            return
        }

        isSubmitting = true
        statusMessage = nil

        let files = selectedImages.map { PhotoUploadFile(data: $0.data, mimeType: $0.mimeType) }

        do {
            let result = try await PhotoAPI.uploadPhotos(
                pin: pinManager.savedPin,
                name: name,
                caption: caption,
                photos: files
            )
            statusIsError = false
            statusMessage = "Uploaded \(result.saved) photo\(result.saved == 1 ? "" : "s"). Thank you!"
            selectedItems = []
            selectedImages = []
            name = ""
            caption = ""
        } catch let error as PhotoUploadException {
            statusIsError = true
            statusMessage = error.message
        } catch {
            statusIsError = true
            statusMessage = "Something went wrong"
        }

        isSubmitting = false
    }
}
