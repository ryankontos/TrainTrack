//
//  TrainFetcher.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import Foundation
import Kanna
import UIKit

class TrainFetcher: ObservableObject {
    
    static var shared: TrainFetcher!
    
    @Published var trains = [Train]()
    
    var allCarriages: [String] {
        
        var array = [String]()
        trains.forEach { train in
            train.carriages.forEach { array.append($0) }
        }
        
        return array
        
    }
    
    private let defaults = UserDefaults.standard
    
    init() {
        
       // NotificationCenter.default.addObserver(self, selector: #selector(contextSaved), name: Notification.Name.NSManagedObjectContextDidSave, object: nil)
        
        self.updateTrainDatabase()
        
       
    }
    
    @objc func contextSaved() {
        
        print("context saved")
        
        DispatchQueue.main.async {
        
        TripFetcher.shared.updateTrips()
            self.update()
            self.objectWillChange.send()
            
        }
        
    }
    
    func update() {
        
        var newTrains = self.trains
        
        addTripsTo(trains: &newTrains)
        
        if newTrains != self.trains {
            self.trains = newTrains
        }
        
    }
    
    func updateTrainDatabase() {
        
        print("Updating trains")
        
        if defaults.stringArray(forKey: "TrainDataCache") == nil {
            setTrains(remote: true)
        } else {
            
            setTrains(remote: false)
            
            DispatchQueue.main.async {
                self.setTrains(remote: true)
            }
            
        }
        
    }
    
    private func setTrains(remote: Bool = false) {
        
        var trains = [Train]()
        
        var tableItems = [String]()
        
        if remote == true {
        
        let remoteItems = getTableItemsRemote()
        
        if remoteItems.isEmpty == false {
            tableItems = remoteItems
        }
            
        }
        
        if tableItems.isEmpty {
            
            tableItems = defaults.stringArray(forKey: "TrainDataCache") ?? [String]()
            
        }
                
        for (i, item) in tableItems.enumerated() {
                    
            if i == 0 {
                continue
            }
                    
            let lines = item.split(whereSeparator: \.isNewline)
                    
            if lines.indices.contains(1) {
                        
                let setCode = lines[0]
                let carString = lines[1]
                        
                let cars = carString.components(separatedBy: " - ")
                
                
                trains.append(Train(set: String(setCode), carriages: cars))
                        
                }
            }
        
        addTripsTo(trains: &trains)
        
        
        self.trains = trains
        
    }
    
    func addTripsTo(trains: inout [Train]) {
        
        for train in trains {
        
            addTripsTo(train: train)
            
        }
        
    }
    
    func addTripsTo(train: Train) {
        
        let trips = TripFetcher.shared.getTrips(for: train.carriages)
        train.trips = trips
        
    }
    
    
    private func getTableItemsRemote() -> [String] {
        
        var tableItems = [String]()
        
        
        
        let url = URL(string: "https://nswtrains.fandom.com/wiki/List_of_Sydney_Trains/NSW_TrainLink_fleets")!
        
       
        
        if let html = try? String(contentsOf: url, encoding: .ascii) {
            if let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
              
                for td in doc.css("tr") {
                    
                    if let className = td.parent?.parent?.className {
                         
                        if className == "wikitable" {
                            tableItems.append(td.content!)
                        }
                        
                    }
                    
                    
                }
                
            }
    }
        
        if tableItems.isEmpty == false {
        
        defaults.set(tableItems, forKey: "TrainDataCache")
            
        }
        
        return tableItems
        
    }
       

    
}
