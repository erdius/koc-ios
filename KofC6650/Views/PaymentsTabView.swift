import SwiftUI

struct PaymentsTabView: View {
    private enum PaymentPage: Identifiable {
        case dues, badge

        var id: Self { self }
    }

    @State private var paymentPage: PaymentPage?
    @Environment(\.openURL) private var openURL

    // No option/amount to pick beforehand, so a plain PayPal link works
    // (unlike dues/badge, which need an option picked first).
    private let donateURL = URL(string: "https://www.paypal.com/donate/?cmd=_s-xclick&hosted_button_id=VQ2AXC3TRTC62")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Dues & Badge Payments")
                    .font(.kofc(18, weight: .semibold))
                    .foregroundColor(KofcColors.onBackground)

                VStack(alignment: .leading, spacing: 12) {
                    Text("💳 Pick an option below, then check out securely with PayPal")
                        .font(.kofc(13, weight: .medium))
                        .foregroundColor(KofcColors.goldMuted)

                    Button {
                        paymentPage = .dues
                    } label: {
                        Text("Pay Membership Dues")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(KofcColors.gold)
                            .padding(.vertical, 12)
                            .background(KofcColors.navy)
                            .cornerRadius(8)
                    }

                    Button {
                        paymentPage = .badge
                    } label: {
                        Text("Pay for a Council Badge")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(KofcColors.gold)
                            .padding(.vertical, 12)
                            .background(KofcColors.navy)
                            .cornerRadius(8)
                    }

                    Text("Pick your dues category or badge type, then finish checkout in PayPal.")
                        .font(.kofc(13))
                        .foregroundColor(KofcColors.helpText)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KofcColors.surface)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 12) {
                    Text("❤️ Support the LAMB Foundation")
                        .font(.kofc(13, weight: .medium))
                        .foregroundColor(KofcColors.goldMuted)

                    Text("Msgr. Michael A. Carey Council 6650 — assisting those with intellectual disabilities.")
                        .font(.kofc(13))
                        .foregroundColor(KofcColors.helpText)

                    Button {
                        openURL(donateURL)
                    } label: {
                        Text("Donate")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(KofcColors.gold)
                            .padding(.vertical, 12)
                            .background(KofcColors.navy)
                            .cornerRadius(8)
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
        .sheet(item: $paymentPage) { page in
            switch page {
            case .dues: DuesPaymentView()
            case .badge: BadgePaymentView()
            }
        }
    }
}
