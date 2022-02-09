//
//  TrainDetailView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct TrainDetailView: View {
    
    @State var carriage: String?
    @State var train: Train
    
    @Binding var showingSheet: Bool
    
    var overviewString: String {
        
        get {
            
            let count = train.trips.count
            
            if count < 1 {
                return "You haven't registered any trips on this train."
            }
            
            var plural = "trips"
            if count == 1 {
                plural = "trip"
            }
                
            return "You've registered \(count) \(plural) on this train."
            
            }
            
        }
    
    var riddenString: String {
        
        get {
            
            var carriages = Set<String>()
            
            for trip in train.trips {
                carriages.insert(trip.carriageCode)
            }
          
            var pluralString = "trip"
            if carriages.count != 1 {
                pluralString += "s"
            }
            
            return "Your trips include \(carriages.count)/\(train.carriages.count) of this train's carriages."
            
            
        }
        
    }
    
    var body: some View {
        
        ZStack {
        
        List {
            
            Section {
                TrainHeaderView(train: train, carriage: carriage, showingSheet: $showingSheet)
                    .listRowBackground(Color.clear)
                
            }
            
            Section(header: LargeHeaderText(text: "Overview")
                    
                    , content: {
  
                        HStack(alignment: .center, spacing: 10) {
                            
                    Circle()
                        .frame(width: 37, height: 37)
                        .foregroundColor(Color.gray.opacity(0.75))
                        .overlay(Text("\(train.trips.count)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 19, weight: .semibold, design: .default)))
                   
                    Text(overviewString)
                        .font(.system(size: 16, weight: .regular, design: .default))
                            
                }
                .padding(.vertical, 20)
                    
                        if train.trips.count > 0 {
                        
                    VStack(alignment: .leading, spacing: 20) {
                        
                        VStack(alignment: .leading, spacing: 15) {
                        
                        VisualTrainView(train: train, highlight: carriage)
                            
            
                            Text(riddenString)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            
                        }
                            
                    }
                    .padding(.vertical, 20)
                        
                
                }
                        
                    }).id(UUID())
            
            if train.trips.count > 0 {
            
            
            Section(header: LargeHeaderText(text: "Trips"), content: {
                
                ForEach(train.trips, id: \.self, content: { trip in
                    
                 
                    
                    TripRowView(trip: trip, showDate: true)
                    
                })

                
                
                
            })
            .id(UUID())
            
            }
            
        }
        .id(UUID())
            #if os(iOS)
        .listStyle(InsetGroupedListStyle())
            #endif
        .onAppear() {
            
            let trips = TripFetcher.shared.getTrips(for: train.carriages)
            print("Setting \(trips.count) trip(s) on appear of TrainDetailView")
            train.setTrips(trips: trips)
            
        }
            
        
        }
        
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(navTitle)
        
        
    }
    
    var navTitle: String {
        
        get {
            
            if let code = carriage {
                
                return code
                
            }
            
            return train.name
            
        }
        
    }
    
}
