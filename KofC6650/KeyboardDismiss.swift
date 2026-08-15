import SwiftUI

extension View {
    /// Adds a "Done" button above the keyboard. Needed specifically for
    /// .numberPad fields (like the council PIN) since that keyboard has no
    /// built-in return/dismiss key at all.
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            }
        }
    }
}
