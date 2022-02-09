//
//  TripFetcher.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import Foundation
import CoreLocation
import UIKit
import CoreData
import MapKit
import Combine


class TripFetcher: ObservableObject {
    
    static var shared = TripFetcher()
    
    
    
    @Published var trips = [Trip]()
    @Published var tripGroups = [TripGroup]()
    
    init() {
        
        updateTrips()
        
    }
    
    func updateTrips() {

        
     //   print("Fetching Trips!")
     
        var returnTrips = [Trip]()
        
        
        let context = TTCloudKit.shared.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        
        
        if let storedTrips = try? context.fetch(fetchRequest) {

            
            for storedTrip in storedTrips {
                
                let location = CLLocation(latitude: storedTrip.latitude, longitude: storedTrip.longitude)
                
                let trip = Trip(date: storedTrip.date!, location: location, carriageCode: storedTrip.carriageCode!, baseStoredTrip: storedTrip)
                
                if let locName = storedTrip.locationName {
                    trip.locationName = locName
                }
                
                returnTrips.append(trip)
                
                
            }
            
            let newTrips = returnTrips.sorted(by: { $0.date.compare($1.date) == .orderedDescending })

            if newTrips != self.trips {
                
                self.trips = newTrips
                print("There are now \(returnTrips.count) trips")
                self.tripGroups = self.getTripGroups()
                TrainFetcher.shared?.update()
                
            }
            
        
        }
    
        
    }
    
    
    private func groupedTripsByDay(_ trips: [Trip]) -> [Date: [Trip]] {
      let empty: [Date: [Trip]] = [:]
      return trips.reduce(into: empty) { acc, cur in
          
            let date = cur.date.startOfDay()
        
          let existing = acc[date] ?? []
          acc[date] = existing + [cur]
      }
    }
    
    
    private func getTripGroups() -> [TripGroup] {

        let tripsVar = self.trips
        
        print("Getting trip groups from \(tripsVar.count) trip(s)")
        
        
        
        var array = [TripGroup]()
        
        for trip in tripsVar {

            
            if let item = array.first(where: { $0.date == trip.date.startOfDay() }) {
                
                item.trips.append(trip)
                
            } else {
                
                array.append(TripGroup(date: trip.date.startOfDay(), trips: [trip]))
                
            }
            
            
        }
        
      
        
        let sorted = array.sorted(by: { $0.date.compare($1.date) == .orderedDescending })
        
        
        
        return sorted
    }
    
    func getTrips(for carriages: [String]) -> [Trip] {
        

        
        var returnTrips = [Trip]()
        
        for trip in trips {
            
            if carriages.contains(trip.carriageCode) {
                
                returnTrips.append(trip)
                
            }
            
        }
        
        return returnTrips
        
    }
    
 
}

class TripGroup: Hashable, Identifiable {
    
    static func == (lhs: TripGroup, rhs: TripGroup) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    
    init(date: Date, trips: [Trip]) {
        
        self.date = date
        self.trips = trips
        
        
        self.id = String(date.timeIntervalSince1970)
    }
    
    var id: String
    
    var uuid = UUID()
    
    var date: Date
    var trips: [Trip]
    
}
