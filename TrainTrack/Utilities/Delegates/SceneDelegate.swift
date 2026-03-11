//
//  SceneDelegate.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        AppShortcutItemManager.shared.setShortcut(shortcutItem)
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: ContentView())
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        LocationManager.shared?.activate()
    }
}
