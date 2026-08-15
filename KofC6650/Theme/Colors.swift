import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, opacity: alpha)
    }

    /// A color that follows the system light/dark appearance, matching
    /// Android's isSystemInDarkTheme()-driven ColorScheme switch.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        }))
    }
}

/// Ported from KofC6650Theme.kt's light/dark ColorScheme and the ad hoc
/// colors used directly in Composables.
enum KofcColors {
    static let navy = Color(hex: 0x1A2F5E)
    static let navyLight = Color(hex: 0x2A4374)
    static let gold = Color(hex: 0xC9A84C)
    static let goldMuted = Color(hex: 0x9A7A2C)

    static let primary = Color(light: navy, dark: navyLight)
    static let onPrimary = gold
    static let secondary = gold
    static let onSecondary = navy

    static let background = Color(light: Color(hex: 0xF0F2F5), dark: Color(hex: 0x14192B))
    static let onBackground = Color(light: Color(hex: 0x222222), dark: Color(hex: 0xEAEAEA))
    static let surface = Color(light: .white, dark: Color(hex: 0x1E2540))
    static let onSurface = Color(light: Color(hex: 0x222222), dark: Color(hex: 0xEAEAEA))
    static let surfaceVariant = Color(light: Color(hex: 0xEDEDED), dark: Color(hex: 0x2A3150))
    static let onSurfaceVariant = Color(light: Color(hex: 0x666666), dark: Color(hex: 0xB0B6C8))

    // Ad hoc colors used directly at specific call sites in the Android app.
    static let errorBackground = Color(hex: 0xFFF5F5)
    static let errorText = Color(hex: 0xC0392B)
    static let emptyText = Color(hex: 0x999999)
    static let locationText = Color(hex: 0x666666)
    static let uploadSuccess = Color(hex: 0x1E6B34)
    static let uploadError = Color(hex: 0xA12626)
    static let helpText = Color(hex: 0x555555)
    static let subtitleText = Color(hex: 0xAABBCC)
}
