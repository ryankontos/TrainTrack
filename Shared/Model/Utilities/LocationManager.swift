//
//  LocationManager.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import Foundation
import MapKit
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static var shared: LocationManager!
    
    var currentLocation: CLLocation?
    
    var currentLocationName: String?
    
    let locationManager = CLLocationManager()
    
    override init() {
        
        super.init()
        activate()
        
        
    }
    
    func activate() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        locationManager.requestLocation()
        
        DispatchQueue.global().async {
            self.updateLocationName()
        }
        
        
    }
    
    func updateLocationName() {
        
        guard let location = self.currentLocation else {
            return
        }
        
        print("Looking up location")
        
            let geocoder = CLGeocoder()
                
            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(location,
                        completionHandler: { (placemarks, error) in
                            
                print("Geocode done")
                            
                if error == nil {
                    
                    let firstLocation = placemarks?[0]
                    
                    if let l = firstLocation?.locality {
                        self.currentLocationName = l
                        
                        print("Current location name is now \(l)")
                        
                    } else {
                        print("No locality")
                    }
                    
                } else {
                    
                    print("Geocoding error: \(error!.localizedDescription)")
                    
                }
                            
            })
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    
    
}

