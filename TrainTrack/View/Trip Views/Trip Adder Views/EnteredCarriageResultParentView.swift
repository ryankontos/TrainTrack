//
//  EnteredCarriageResultParentView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct EnteredCarriageResultParentView: View {
    
    @ObservedObject var trainFetcher = TrainFetcher.shared

    @Binding var showingSheet: Bool
    
    var trainLookup = TrainLookup()
    var carriage: String

    
    var body: some View {
        
        if let train = trainLookup.findTrain(withCarriage: carriage, from: trainFetcher.trains) {
         
            TrainDetailView(carriage: carriage, train: train, showingSheet: $showingSheet)
                
            
            
        } else {
            
            Text("No Match")
        }
        
    }
}
