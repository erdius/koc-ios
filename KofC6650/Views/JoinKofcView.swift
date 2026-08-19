import SwiftUI

struct JoinKofcView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private static let joinURL = URL(string: "https://www.kofc.org/get-involved/join-kofc")!
    private static let promoCode = "BLESSEDMCGIVNEY"

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Not a member yet?")
                    .font(.kofc(19, weight: .semibold))
                    .foregroundColor(KofcColors.onBackground)
                    .padding(.top, 24)

                if let qrImage = QRCodeGenerator.image(for: Self.joinURL.absoluteString) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                }

                Button {
                    openURL(Self.joinURL)
                } label: {
                    Text(Self.joinURL.absoluteString)
                        .font(.kofc(13))
                        .foregroundColor(KofcColors.primary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 6) {
                    Text("Use code for a free one-year membership:")
                        .font(.kofc(13))
                        .foregroundColor(KofcColors.locationText)
                    Text(Self.promoCode)
                        .font(.kofc(22, weight: .bold))
                        .foregroundColor(KofcColors.goldMuted)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(KofcColors.background)
            .navigationTitle("Join Council 6650")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
