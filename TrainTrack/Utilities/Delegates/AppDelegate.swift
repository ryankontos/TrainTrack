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
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        TrainFetcher.shared = TrainFetcher()
        
        DispatchQueue.main.async {
            
            LocationManager.shared = LocationManager()
            
            self.addQuickActions()
            
        }
        
        
        
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        
        if let shortcutItem = options.shortcutItem {
            
            DispatchQueue.main.async {
                AppShortcutItemManager.shared.setShortcut(shortcutItem)
            }
            
           
        }
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    
    
    func addQuickActions() {
            var addUserInfo: [String: NSSecureCoding] {
                return ["name" : "new" as NSSecureCoding]
            }
        
            var scanUserInfo: [String: NSSecureCoding] {
            return ["name" : "scan" as NSSecureCoding]
            }
            
            
            UIApplication.shared.shortcutItems = [
                UIApplicationShortcutItem(type: "New Trip", localizedTitle: "New Trip", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(type: .add), userInfo: addUserInfo),
                
                
                UIApplicationShortcutItem(type: "Scan Trip", localizedTitle: "Scan Trip", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(type: .capturePhoto), userInfo: scanUserInfo),
                
            ]
        }

}

