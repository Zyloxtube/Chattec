import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)

        let host = UIHostingController(rootView: RootView())
        // Let SwiftUI views extend under the status bar & home indicator
        host.view.insetsLayoutMarginsFromSafeArea = false
        host.view.backgroundColor = UIColor(red: 0x0f/255.0,
                                            green: 0x13/255.0,
                                            blue: 0x19/255.0,
                                            alpha: 1)

        window.rootViewController = host
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
