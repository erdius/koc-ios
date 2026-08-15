import SwiftUI

/// Full-app gate shown at launch until the correct council PIN is entered.
/// Once verified, PinManager persists it, so this never shows again on this
/// device.
struct PinGateView: View {
    @ObservedObject var pinManager: PinManager

    @State private var pinInput: String = ""
    @State private var showIncorrect = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(KofcColors.gold).frame(width: 68, height: 68)
                Text("K").font(.kofc(32, weight: .bold)).foregroundColor(KofcColors.navy)
            }
            .padding(.bottom, 8)

            Text("Knights of Columbus")
                .font(.kofc(27, weight: .semibold))
                .foregroundColor(KofcColors.onBackground)
                .multilineTextAlignment(.center)
            Text("Council 6650 — Cary & Apex, NC")
                .font(.kofc(17))
                .foregroundColor(KofcColors.goldMuted)
                .multilineTextAlignment(.center)

            Text("Enter the council PIN to continue")
                .font(.kofc(19, weight: .semibold))
                .foregroundColor(KofcColors.onBackground)
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            SecureField("Council PIN", text: $pinInput)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 200)
                .multilineTextAlignment(.center)
                .onChange(of: pinInput) { newValue in
                    showIncorrect = false
                    pinManager.verify(newValue)
                }

            Button {
                if !pinManager.verify(pinInput) {
                    showIncorrect = true
                }
            } label: {
                Text("Unlock")
                    .foregroundColor(KofcColors.gold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(KofcColors.navy)
                    .cornerRadius(8)
            }

            if showIncorrect {
                Text("Incorrect PIN")
                    .font(.kofc(13))
                    .foregroundColor(KofcColors.uploadError)
            }

            Divider()
                .padding(.vertical, 12)

            VStack(spacing: 6) {
                Text("Not a member yet?")
                    .font(.kofc(17, weight: .semibold))
                    .foregroundColor(KofcColors.onBackground)

                (
                    Text("Sign up here").underline().foregroundColor(KofcColors.gold)
                        + Text(" and use code ").foregroundColor(KofcColors.onBackground)
                        + Text("BLESSEDMCGIVNEY").fontWeight(.semibold).foregroundColor(KofcColors.onBackground)
                        + Text(" for a free one-year membership. We're Council 6650!")
                            .foregroundColor(KofcColors.onBackground)
                )
                .font(.kofc(16))
                .multilineTextAlignment(.center)
                .onTapGesture {
                    if let url = URL(string: "https://www.kofc.org/get-involved/join-kofc/") {
                        openURL(url)
                    }
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KofcColors.background)
        .keyboardDoneButton()
    }
}
