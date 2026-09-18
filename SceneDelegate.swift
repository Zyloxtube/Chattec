import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)

        let host = UIHostingController(rootView: RootView())
        if #available(iOS 16.4, *) {
            host.safeAreaRegions = []
        }

        window.rootViewController = host
        self.window = window
        window.makeKeyAndVisible()
    }
}SceneDelegate.swift
