//
//  TripInfoView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 21/11/20.
//

import SwiftUI
import MapKit

struct TripInfoView: View {
    
    @State var trip: Trip
    
    let trainLookup = TrainLookup()
    
    var body: some View {
        
        ScrollView {
          
            Text(trip.carriageCode)
            Text(trainLookup.findTrain(withCarriage: trip.carriageCode, from: TrainFetcher.shared.trains)!.name)
            Text(trip.locationName)
            Text("\(trip.date.userFriendlyRelativeString()), \(trip.date.formattedTime())")
            
            
        if let location = trip.location {
            
            if let name = trip.placemark?.locality {
                Text(name)
            }
            
        MapView(region: trip.mapRegion, locationToPin: location)
            .contextMenu(menuItems: {
                
                Button(action: {}, label: {
                    
                    Text("Edit Location")
                    Image(systemName: "pencil")
                    
                })
                
                Button(action: {}, label: {
                    
           
                    Text("Remove Location")
                    Image(systemName: "trash")
                    
                    
                    .foregroundColor(.red)
                    
                })
                
                
                
                
            })
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.horizontal, 50)
        
                
            }
            
            
        }
  
        
        
    }
    
 
   
    
        
    
    
}

