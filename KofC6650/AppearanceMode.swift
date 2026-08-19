import SwiftUI

/// Global light/dark mode preference. A singleton (matches FontScale's
/// pattern) -- ContentView observes it directly at the root so changing it
/// anywhere (the About sheet) applies .preferredColorScheme app-wide.
final class AppearanceMode: ObservableObject {
    static let shared = AppearanceMode()

    enum Mode: String, CaseIterable, Identifiable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        var id: String { rawValue }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    @Published var mode: Mode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.key) }
    }

    private static let key = "kofc_appearance_mode"

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.key)
        mode = Mode.allCases.first { $0.rawValue == saved } ?? .system
    }
}
