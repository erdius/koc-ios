import UIKit

/// Bridges UIKit's Home Screen quick-action lifecycle into the SwiftUI app.
/// SwiftUI's App/Scene has no direct hook for
/// UIApplicationShortcutItem, so this stays minimal -- just enough to
/// capture the tapped item and forward it via NotificationCenter (warm tap)
/// or a static var (cold launch, read once ContentView appears).
final class AppDelegate: NSObject, UIApplicationDelegate {
    static var launchShortcutItem: UIApplicationShortcutItem?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if let item = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            AppDelegate.launchShortcutItem = item
        }
        UIApplication.shared.shortcutItems = QuickAction.allShortcutItems
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        NotificationCenter.default.post(name: .quickActionTapped, object: shortcutItem)
        completionHandler(true)
    }
}

extension Notification.Name {
    static let quickActionTapped = Notification.Name("quickActionTapped")
}

enum QuickAction: String {
    case recentPhotos = "com.erdman.kofc6650.recentPhotos"
    case submitPhotos = "com.erdman.kofc6650.submitPhotos"

    /// Matches ContentView's TabView tags.
    var tabIndex: Int {
        switch self {
        case .recentPhotos: return 3
        case .submitPhotos: return 2
        }
    }

    static var allShortcutItems: [UIApplicationShortcutItem] {
        [
            UIApplicationShortcutItem(
                type: QuickAction.recentPhotos.rawValue,
                localizedTitle: "Recent Photos",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "photo.on.rectangle.fill")
            ),
            UIApplicationShortcutItem(
                type: QuickAction.submitPhotos.rawValue,
                localizedTitle: "Submit Photos",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "camera.fill")
            ),
        ]
    }
}
