//
//  AddTripCapsule.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 15/1/21.
//

import SwiftUI

struct AddTripCapsule: View {
    var body: some View {
        
        Capsule()
            .foregroundColor(Color.blue)
            .frame(width: 75, height: 30)
            .overlay(
                
                Text("ADD")
                    .foregroundColor(.white)
                    .textCase(.none)
                    .font(.system(size: 15, weight: .semibold, design: .default))
            
            )
        
    }
}

struct AddTripCapsule_Previews: PreviewProvider {
    static var previews: some View {
        AddTripCapsule()
    }
}
