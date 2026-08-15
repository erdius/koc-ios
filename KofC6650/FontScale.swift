import SwiftUI

/// Global text-size preference. A singleton (not threaded through every
/// view's init) because `Font.kofc(...)` is called from dozens of call
/// sites -- ContentView observes it directly so changing it anywhere (the
/// About sheet) triggers a full re-render, which re-evaluates every
/// Font.kofc(...) call with the new multiplier.
final class FontScale: ObservableObject {
    static let shared = FontScale()

    enum Preset: String, CaseIterable, Identifiable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        case extraLarge = "X-Large"

        var id: String { rawValue }

        var multiplier: CGFloat {
            switch self {
            case .small: return 0.85
            case .medium: return 1.0
            case .large: return 1.25
            case .extraLarge: return 1.5
            }
        }
    }

    @Published var preset: Preset {
        didSet { UserDefaults.standard.set(preset.rawValue, forKey: Self.key) }
    }

    private static let key = "kofc_font_scale_preset"

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.key)
        preset = Preset.allCases.first { $0.rawValue == saved } ?? .medium
    }
}

extension Font {
    static func kofc(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size * FontScale.shared.preset.multiplier, weight: weight)
    }
}
