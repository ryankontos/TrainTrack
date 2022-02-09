//
//  MapView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 5/12/20.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    
    @State var region: MKCoordinateRegion
    var locationToPin: CLLocation
    
    var body: some View {
        
        Map(coordinateRegion: $region, annotationItems: [IdentifiableLocation(location: locationToPin)], annotationContent: { value in
        
            return MapMarker(coordinate: value.location.coordinate)
        
    })
        
    }
}

struct IdentifiableLocation: Identifiable {
    
    internal init(location: CLLocation) {
        self.location = location
        self.id = "\(location.description)"
        
    }
    
    var id: String
    var location: CLLocation
    
}
