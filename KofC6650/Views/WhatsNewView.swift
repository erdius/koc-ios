import SwiftUI

struct WhatsNewView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("What's New")
                .font(.kofc(22, weight: .bold))
                .foregroundColor(KofcColors.onBackground)

            Text(WhatsNew.changelog)
                .font(.kofc(15))
                .foregroundColor(KofcColors.onBackground)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button(action: onDismiss) {
                Text("Got It")
                    .font(.kofc(16, weight: .semibold))
                    .foregroundColor(KofcColors.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(KofcColors.navy)
                    .cornerRadius(8)
            }
        }
        .padding(24)
        .background(KofcColors.background)
    }
}
