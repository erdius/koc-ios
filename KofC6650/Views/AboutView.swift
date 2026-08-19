import SwiftUI
import UIKit

struct AboutView: View {
    @ObservedObject var pinManager: PinManager
    @ObservedObject private var fontScale = FontScale.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "Version \(version) (build \(build))"
    }

    private func reportProblem() {
        let device = UIDevice.current
        let body = """


        ---
        \(versionString)
        \(device.systemName) \(device.systemVersion)
        \(device.model)
        """
        var components = URLComponents(string: "mailto:bird.dog@erdius.net")
        components?.queryItems = [
            URLQueryItem(name: "subject", value: "KofC 6650 App - Problem Report"),
            URLQueryItem(name: "body", value: body),
        ]
        guard let url = components?.url else { return }
        openURL(url)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(KofcColors.gold).frame(width: 56, height: 56)
                    Text("K").font(.kofc(26, weight: .bold)).foregroundColor(KofcColors.navy)
                }
                .padding(.top, 24)

                Text("Knights of Columbus")
                    .font(.kofc(21, weight: .semibold))
                    .foregroundColor(KofcColors.onBackground)
                Text("Council 6650 — Cary & Apex, NC")
                    .font(.kofc(13))
                    .foregroundColor(KofcColors.goldMuted)

                Text(versionString)
                    .font(.kofc(13))
                    .foregroundColor(KofcColors.locationText)

                Spacer().frame(height: 8)

                VStack(spacing: 8) {
                    Text("Text Size")
                        .font(.kofc(14, weight: .semibold))
                        .foregroundColor(KofcColors.onBackground)

                    Picker("Text Size", selection: $fontScale.preset) {
                        ForEach(FontScale.Preset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 8)

                Button(action: reportProblem) {
                    Text("Report a Problem")
                        .foregroundColor(KofcColors.gold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(KofcColors.navy)
                        .cornerRadius(8)
                }

                Button {
                    pinManager.clear()
                    dismiss()
                } label: {
                    Text("Reset saved PIN")
                        .foregroundColor(KofcColors.gold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(KofcColors.navy)
                        .cornerRadius(8)
                }

                Text("You'll be asked for the council PIN again next time you open the app.")
                    .font(.kofc(12))
                    .foregroundColor(KofcColors.locationText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(KofcColors.background)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
