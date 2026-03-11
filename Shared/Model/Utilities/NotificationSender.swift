//
//  NotificationSender.swift
//  TrainTrack Sydney
//
//  Created by Ryan on 22/4/2024.
//

import Foundation
import UserNotifications

class NotificationSender {
    
    func scheduleNotification(title: String, body: String, date: Date = Date()) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        center.add(request) { (error) in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
    
}
