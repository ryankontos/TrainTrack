//
//  AppShortcutHandler.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 22/1/2022.
//

import Foundation
import UIKit

struct AppShortcutItemManager {
    
    static var shared = AppShortcutItemManager()
    
    private var shortcut: UIApplicationShortcutItem?
    private var delegate: AppShortcutItemDelegate?
    
    mutating func setDelegate(_ delegate: AppShortcutItemDelegate) {
        
        if let shortcut = self.shortcut {
            delegate.handle(shortcutItem: shortcut)
        } else {
            self.delegate = delegate
        }
        
    }
    
    mutating func setShortcut(_ shortcut: UIApplicationShortcutItem) {
        
        if let delegate = self.delegate {
            delegate.handle(shortcutItem: shortcut)
        } else {
            self.shortcut = shortcut
        }
        
    }
    
    

    
}

protocol AppShortcutItemDelegate {
    
    func handle(shortcutItem: UIApplicationShortcutItem)
    
}
