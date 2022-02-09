//
//  TripAdder.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import Foundation
import UIKit
import CoreData

class TripAdder {
    
    func addTrip(withCode code: String) {
        
        
        let context = TTCloudKit.shared.persistentContainer.viewContext
     
        let new = NSEntityDescription.insertNewObject(forEntityName: "StoredTrip", into: context) as! StoredTrip
        new.carriageCode = code
        new.date = Date()
        
        new.locationName = LocationManager.shared.currentLocationName
        
        if let loc = LocationManager.shared.currentLocation?.coordinate {
            
            new.latitude = loc.latitude
            new.longitude = loc.longitude
            
        }

        
        context.insert(new)
        try? context.save()

        TripFetcher.shared.updateTrips()
        
       
        
    }
    
    
}

