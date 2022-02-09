//
//  TrainHeaderView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 21/11/20.
//

import SwiftUI
#if canImport(SPAlert)
import SPAlert
#endif

struct TrainHeaderView: View {
    
    let adder = TripAdder()
    
    var train: Train
    @State var carriage: String?
    
    @Binding var showingSheet: Bool
    
    let sets = TrainSets()
    
   
    
    var body: some View {
        
        HStack(spacing: 20) {
      
        Image(getSet().setName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            VStack(alignment: .leading) {
                
                Text(train.name)
                    .font(.system(size: 25, weight: .semibold, design: .default))
                    .textCase(.none)
                
                
                
                   // .foregroundColor(Color(UIColor.label))
                Text(getSet().setName)
                    .font(.system(size: 18, weight: .regular, design: .default))
                    .textCase(.none)
                   // .foregroundColor(Color(UIColor.label))
                
                if carriage != nil {
                
             
                Button(action: {
                    
                    DispatchQueue.main.async {
                    
                        self.adder.addTrip(withCode: carriage!)
                    
                        
                        showingSheet = false
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        
                            #if os(iOS)
                            
                        SPAlert.present(title: "Trip Saved", preset: .done)
                            
                            #endif
                        
                    }
                        
                    }
                    
                    
                }, label: {
                    
                    AddTripCapsule()
                    
                })
                
            }
                
            }
       
            
            Spacer()
            
        }
        
        
        
    }
    
    func getSet() -> TrainSet {
        
        sets.matchSet(to: train)!
        
    }
}


