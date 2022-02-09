//
//  Date.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 5/12/20.
//

import Foundation

extension Date {
    
    func idString() -> String {
        
        return "\(self.formattedDate()), \(self.formattedTime())"
        
    }
    
    func userFriendlyRelativeString(at date: Date = Date()) -> String {
        
        let daysUntilDate = self.daysUntil(at: date)
        var dayText: String
        
        let dateFormatter  = DateFormatter()
        if self.year() == date.year() {
            
            dateFormatter.dateFormat = "d MMM"
            
        } else {
            
            dateFormatter.dateFormat = "d MMM YYYY"
            
        }
        
        let dateString = dateFormatter.string(from: self)
        
        if daysUntilDate < -1 {
            
           return dateString
            
        }
        
        switch daysUntilDate {
        case -1:
            dayText = "Yesterday"
        case 0:
            dayText = "Today"
        case 1:
            dayText = "Tomorrow"
        default:
            
            if daysUntilDate < 7 {
            
            let dateFormatter  = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            dayText = dateFormatter.string(from: self)
                
            } else {
                
                return dateString
                
            }
        }
        
        return dayText
        
    }
    
    var hasOccured: Bool {
        
        get {
            
            if self.timeIntervalSinceNow > 0 {
                return false
            } else {
                return true
            }
            
        }
        
    }
    
    func daysUntil(at date: Date = Date()) -> Int {
        
        return Int(self.startOfDay().timeIntervalSince(date.startOfDay()))/60/60/24
        
    }
    
    func getDayOfWeekName(returnTodayIfToday: Bool) -> String {
        
        var returnText: String
        
        let dateFormatter  = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        returnText = dateFormatter.string(from: self)
        
        if self.daysUntil() == 0, returnTodayIfToday {
            
            returnText = "Today"
            
        }
        
        if self.daysUntil() == 1, returnTodayIfToday {
            
            returnText = "Tomorrow"
            
        }
        
        return returnText
        
    }
    
    func weekOfYear() -> Int {
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        return calendar.components([.weekOfYear], from: self).weekOfYear!
        
        
    }
    
    
    private func is24Hour() -> Bool {
        let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)!

        return dateFormat.firstIndex(of: "a") == nil
    }
    
    func formattedTime() -> String {
        
        
        let dateFormatter  = DateFormatter()
        
        if is24Hour() {
            dateFormatter.dateFormat = "HH:mm"
        } else {
            dateFormatter.dateFormat = "h:mma"
        }
        
        return dateFormatter.string(from: self)
    }
    
    func formattedTimeTwelve() -> String {
        
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU")
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        
        let r = formatter.string(from: self)
             
        return r
    }
    
    func formattedDate() -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy"
        return dateFormatter.string(from: self)
        
    }
    
    func year() -> Int {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        
        return Int(dateFormatter.string(from: self))!
        
    }
    
    func startOfDay() -> Date {
        
        return Calendar.current.startOfDay(for: self)

        
    }
    
    func endOfDay() -> Date {
        
        return self.startOfDay().addingTimeInterval(86400)
        
    }
    
}
