import SwiftUI

struct BadgePaymentView: View {
    private enum BadgeOption: String, CaseIterable, Identifiable {
        case badgeOnly = "Name Badge Only"
        case badgeAndMagnet = "Name Badge & Magnet"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .badgeOnly: return "Name Badge Only — $15.00"
            case .badgeAndMagnet: return "Name Badge & Magnet — $18.00"
            }
        }
    }

    @State private var selectedOption: BadgeOption = .badgeOnly
    @State private var nameOnBadge = ""
    @State private var officerRole = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    private var canSubmit: Bool {
        !nameOnBadge.trimmingCharacters(in: .whitespaces).isEmpty && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Choose an option") {
                    Picker("Badge", selection: $selectedOption) {
                        ForEach(BadgeOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("How name should appear") {
                    TextField("Full name", text: $nameOnBadge)
                }

                Section("Officer role (optional)") {
                    TextField("Officer role", text: $officerRole)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(KofcColors.uploadError)
                }

                Section {
                    Button {
                        submit()
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Continue to PayPal")
                            }
                            Spacer()
                        }
                    }
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle("Council Badge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .keyboardDoneButton()
        }
    }

    private func submit() {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                let url = try await PayPalSubmitter.submit(
                    hostedButtonId: "EJHU5WCSMXMXQ",
                    fields: [
                        "on0": "Select One",
                        "os0": selectedOption.rawValue,
                        "on1": "How name should appear",
                        "os1": nameOnBadge,
                        "on2": "Officer role (optional)",
                        "os2": officerRole,
                        "currency_code": "USD",
                    ]
                )
                isSubmitting = false
                openURL(url)
                dismiss()
            } catch {
                isSubmitting = false
                errorMessage = "Couldn't reach PayPal. Please try again."
            }
        }
    }
}
