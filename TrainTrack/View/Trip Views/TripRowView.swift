//
//  TripRowView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import SwiftUI

struct TripRowView: View {
    
    @State var trip: Trip
    @State var showDate: Bool
    
    @State var showTrainName = true
    @State var showRelativeDate = false
    
    let trainLookup = TrainLookup()
    
    var body: some View {
        
        VStack {
            
        HStack(spacing: 15) {
            
        VStack(alignment: .leading, spacing: 3) {
            
            Text(title)
                .font(Font.system(size: 22, weight: .medium, design: .default))
            Text(setName)
                .font(Font.system(size: 16, weight: .regular, design: .default))
            Text("\(dateString), \(trip.locationName)")
                .foregroundColor(.secondary)
                .font(Font.system(size: 15, weight: .regular, design: .default))
            
            
            
        }
                
        Spacer()
                
        
        }

            
        }
        .padding(.vertical, 7)
        
    }
    
    var title: String {
        
        var titleString = trip.carriageCode
        
        if showTrainName {
            
            if let trainName = trainLookup.findTrain(withCarriage: trip.carriageCode, from: TrainFetcher.shared.trains)?.name {
                
                titleString = "\(trainName) - \(titleString)"
                
            }
            
        }
        
        return titleString
        
    }
    
    var setName: String {
        
        if let train = trainLookup.findTrain(withCarriage: trip.carriageCode, from: TrainFetcher.shared.trains), let name = TrainSets.shared.matchSet(to: train)?.setName {
            
            return name
            
        } else {
            
            return "Unknown Set"
            
        }
        
    }
    
    var dateString: String {
        
        var dateString = trip.date.formattedTime()
        
        if showDate {
            
            dateString = "\(trip.date.formattedDate()), \(dateString)"
            
        }
        
        return dateString
        
    }
    
}

