import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)

        let host = UIHostingController(rootView: RootView())

        // Official API since iOS 16.4 — removes all safe area insets from
        // the hosting controller so SwiftUI gets the full screen bounds.
        if #available(iOS 16.4, *) {
            host.safeAreaRegions = []
        }

        window.rootViewController = host
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
