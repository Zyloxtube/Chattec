import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)

        let host = UIHostingController(rootView: RootView())
        host._disableSafeArea = true

        window.rootViewController = host
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
