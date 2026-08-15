import Foundation

/// Shared, persisted PIN state. Entering the correct PIN anywhere (Submit
/// Photos or the Recent Photos gate) remembers it so it's never asked for
/// again on this device, in either place.
@MainActor
final class PinManager: ObservableObject {
    static let correctPin = "1882"
    private static let storageKey = "kofc_saved_pin"

    @Published private(set) var savedPin: String

    var isUnlocked: Bool { savedPin == Self.correctPin }

    init() {
        savedPin = UserDefaults.standard.string(forKey: Self.storageKey) ?? ""
    }

    @discardableResult
    func verify(_ pin: String) -> Bool {
        guard pin == Self.correctPin else { return false }
        savedPin = pin
        UserDefaults.standard.set(pin, forKey: Self.storageKey)
        return true
    }

    func clear() {
        savedPin = ""
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }
}
