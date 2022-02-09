//
//  VisualTrainView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct VisualTrainView: View {
    
    @State var train: Train
    
    @State var highlight: String?
    
    var body: some View {
       
        HStack {
            
            ForEach(train.carriages, id: \.self, content: { carriage in
                
             
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(Color(computeBoxColour(for: carriage)))
                    .frame(height: 27)
                    .overlay(Text(tripsFor(carriage: carriage))
                                .foregroundColor(.white))
                    
                
                
            })
            
            
        }
        
        
    }
    
    func computeBoxColour(for carriage: String) -> UIColor {
        
        
        if let uH = highlight, carriage == uH {
            return UIColor.green.withAlphaComponent(0.5)
        } else {
            return UIColor.gray.withAlphaComponent(0.75)
        }
        
        
    }
    
    func tripsFor(carriage: String) -> String {
        
        var counter = 0
        
        for trip in train.trips {
            
            if trip.carriageCode == carriage {
                counter += 1
            }
            
        }
        
        if counter > 0 {
        
        return String(counter)
            
        } else {
            
            return ""
        }
        
    }
    
}


