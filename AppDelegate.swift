import UIKit
import SwiftUI

final class FullScreenHostingController<Content: View>: UIHostingController<Content> {
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        additionalSafeAreaInsets = .zero
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)

        let host = FullScreenHostingController(rootView: RootView())

        window.rootViewController = host
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
