//
//  TrainLookup.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import Foundation

class TrainLookup {
    
    func findTrain(withCarriage lookupCarriage: String, from trains: [Train]) -> Train? {
        
        for train in trains {
            
            for carriage in train.carriages {
                
                if carriage == lookupCarriage {
                    return train
                }
                
            }
            
            
        }
        
        return nil
        
    }
    
    
    
    
}
