import SwiftUI

struct DirectorsOfficersView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("App") {
                    ForEach(LeadershipDirectory.developer) { contact in
                        LeadershipRow(contact: contact)
                    }
                }
                Section("Officers") {
                    ForEach(LeadershipDirectory.officers) { contact in
                        LeadershipRow(contact: contact)
                    }
                }
                Section("Directors") {
                    ForEach(LeadershipDirectory.directors) { contact in
                        LeadershipRow(contact: contact)
                    }
                    // Without this, the last row's content can sit flush
                    // against the sheet's bottom edge/home indicator with
                    // no breathing room.
                    Color.clear.frame(height: 16).listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Directors & Officers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct LeadershipRow: View {
    let contact: LeadershipContact

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            guard let email = contact.email, let url = URL(string: "mailto:\(email)") else { return }
            openURL(url)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.title)
                        .font(.kofc(12, weight: .semibold))
                        .foregroundColor(KofcColors.goldMuted)
                    Text(contact.name)
                        .font(.kofc(16))
                        .foregroundColor(KofcColors.onSurface)
                }

                Spacer()

                if contact.email != nil {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(KofcColors.primary)
                }
            }
            .contentShape(Rectangle())
        }
        .disabled(contact.email == nil)
        .buttonStyle(.plain)
    }
}
