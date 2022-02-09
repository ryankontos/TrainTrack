//
//  Train.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import Foundation

class Train: Identifiable, Equatable {
    static func == (lhs: Train, rhs: Train) -> Bool {
        return lhs.id == rhs.id
    }
    
   
    var id: String
    
    internal init(set: String, carriages: [String]) {
        
        self.name = set
        self.carriages = carriages
        self.id = set
        //self.id = set
      
    }
    
    let name: String
    let carriages: [String]
    var trips = [Trip]()
    
    var isRidden: Bool {
        
        get {
            
            return !trips.isEmpty
            
        }
        
    }
    
    func setTrips(trips: [Trip]) {
        
        self.trips = trips
        
       /* var returnString = name
        trips.forEach({returnString += "\($0.date.timeIntervalSinceReferenceDate)"})
        self.id = returnString */
        
    }

}
