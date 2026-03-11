//
//  AppDelegate.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import UIKit
import CoreData
import CloudKit

var shortcutItemToProcess: UIApplicationShortcutItem?

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 1. Core Data (CloudKit only)
        TTCloudKit.shared = TTCloudKit()

        // 2. Location
        LocationManager.shared = LocationManager()

        // 3. Fleet + images (async, non-blocking)
        Task { @MainActor in
            FleetStore.shared.load()
            FleetImageStore.shared.preloadAll()
        }

        // 4. Notifications
        UNUserNotificationCenter.current().delegate = self

        // 5. Quick actions
        addQuickActions()

        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(.banner)
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            DispatchQueue.main.async {
                AppShortcutItemManager.shared.setShortcut(shortcutItem)
            }
        }
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    private func addQuickActions() {
        var addUserInfo: [String: NSSecureCoding] { ["name": "new" as NSSecureCoding] }
        var scanUserInfo: [String: NSSecureCoding] { ["name": "scan" as NSSecureCoding] }

        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(type: "New Trip", localizedTitle: "New Trip", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(type: .add), userInfo: addUserInfo),
            UIApplicationShortcutItem(type: "Scan Trip", localizedTitle: "Scan Trip", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(type: .capturePhoto), userInfo: scanUserInfo),
        ]
    }
}
