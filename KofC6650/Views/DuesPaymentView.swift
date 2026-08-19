import SwiftUI

struct DuesPaymentView: View {
    private enum DuesOption: String, CaseIterable, Identifiable {
        case duesOnly = "Annual Membership Dues"
        case duesPlusPenny = "Dues + Penny-a-Day Fund"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .duesOnly: return "Annual Membership Dues — $39.88"
            case .duesPlusPenny: return "Dues + Penny-a-Day Fund — $43.66"
            }
        }
    }

    @State private var selectedOption: DuesOption = .duesOnly
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Choose an option") {
                    Picker("Dues", selection: $selectedOption) {
                        ForEach(DuesOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
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
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("Membership Dues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submit() {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                let url = try await PayPalSubmitter.submit(
                    hostedButtonId: "WZEZAAQZP7HAU",
                    fields: [
                        "on0": "Select One",
                        "os0": selectedOption.rawValue,
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
