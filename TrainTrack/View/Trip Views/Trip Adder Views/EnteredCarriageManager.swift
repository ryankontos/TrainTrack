//
//  EnteredCarriageManager.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 23/1/2022.
//

import Foundation
import SwiftUI

class EnteredCarriageManager: ObservableObject {
    
    @Published var enteredText: String = ""
    @Published var pushTrainInfoView = false
    
    @Published var showCamera = false
    
    init(camera: Bool) {
        showCamera = camera
    }
    
    func gotFullCarriageCodeExternally(code: String) {
        
        DispatchQueue.main.async {
        
            self.enteredText = code
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.pushTrainInfoView = true
            }
        
        }
        
        
    }
    
}
