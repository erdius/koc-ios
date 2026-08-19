import SwiftUI

@main
struct KofC6650App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        // Direct .font() on the Text inside .tabItem is unreliable across
        // iOS versions for the classic bottom TabView -- the appearance
        // proxy is the robust way to size tab bar labels.
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
        ]
        UITabBarItem.appearance().setTitleTextAttributes(attributes, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(attributes, for: .selected)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
