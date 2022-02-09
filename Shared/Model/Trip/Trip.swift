//
//  Trip.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 5/12/20.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit

class Trip: Equatable, Identifiable, Hashable {
    
    
    internal init(date: Date, location: CLLocation, carriageCode: String, baseStoredTrip: StoredTrip) {

        self.date = date
        self.location = location
        self.mapRegion = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.carriageCode = carriageCode
        self.baseStoredTrip = baseStoredTrip
        self.id = UUID()
        
        
        
    }
    
    
    var id: UUID
    
    
    var mapRegion: MKCoordinateRegion
    var date: Date
    var location: CLLocation
    var carriageCode: String
    
    @Published var locationName = "Unknown Location"
    
    var baseStoredTrip: StoredTrip
    @Published var placemark: CLPlacemark?
    var formattedDate: String {
        
        get {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d, yyyy"
            return dateFormatter.string(from: date)
            
            
        }
        
    }
    
   
    
    
    
    static func == (lhs: Trip, rhs: Trip) -> Bool {
        
        return lhs.date.timeIntervalSince1970 == rhs.date.timeIntervalSince1970 && lhs.carriageCode == rhs.carriageCode
        
    }
    
     func lookUpLocation(from location: CLLocation) {
     
        print("Looking up location")
        
            let geocoder = CLGeocoder()
                
            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(location,
                        completionHandler: { (placemarks, error) in
                            
                print("Geocode done")
                            
                if error == nil {
                    
                    print("Error was nil")
                    let firstLocation = placemarks?[0]
                    
                    print("Firstlocation \(String(describing: firstLocation))")
                    
                    
                    
                    
                    self.placemark = firstLocation
                    
                    if let l = firstLocation?.locality {
                        self.locationName = l
                        self.baseStoredTrip.locationName = l
                        
                        
                        let context = TTCloudKit.shared.persistentContainer.viewContext
                
                        try? context.save()
                        
                    } else {
                        print("No locality")
                    }
                    
                } else {
                    
                    print("Geocoding error: \(error!.localizedDescription)")
                    
                }
                            
            })
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    
}
