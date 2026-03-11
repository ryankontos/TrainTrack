//
//  TrainCarriageTripCountView.swift
//  TrainTrack Sydney
//
//  Created by Ryan on 17/4/2024.
//

import SwiftUI

struct TrainCarriageTripCountView: View {
    var body: some View {
        
        HStack(spacing: -6) {
           
            getCarView(.front)
            getCarView(.middle)
            getCarView(.middle)
            getCarView(.middle)
            getCarView(.middle)
            getCarView(.middle)
            getCarView(.middle)
            getCarView(.rear)
            
        }
      
        
        
    }
    
    func getCarView(_ type: CarType) -> some View {
        
        VStack {
            
            Group {
                
                switch type {
                case .front:
                    Image(systemName: "train.side.front.car")
                        .scaleEffect(x: -1, y: 1)
                case .middle:
                    Image(systemName: "train.side.middle.car")
                case .rear:
                    Image(systemName: "train.side.front.car")
                       
                }
                
            }
            
           
                .font(.system(size: 34))
               
            
            Text("5")
                .font(.system(size: 22))
            
        }
        
    }
    
    enum CarType: String {
        case front
        case middle
        case rear
    }
    
}

#Preview {
    
    List {
        
        TrainCarriageTripCountView()
        TrainCarriageTripCountView()
        TrainCarriageTripCountView()
        TrainCarriageTripCountView()
        
    }
    
  
}
