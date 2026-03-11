//
//  AddTripCapsule.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 15/1/21.
//

import SwiftUI

struct AddTripCapsule: View {
    
    @Binding var added: Bool
    
    var body: some View {
        
        Capsule()
            .foregroundColor(added ? .gray : .blue)
            .frame(width: added ? 75 : 53, height: 30)
            .overlay(
                
                Text(added ? "ADDED" : "ADD")
                    .foregroundColor(.white)
                    .textCase(.none)
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    

            
            )
        
    }
}

struct AddTripCapsule_Previews: PreviewProvider {
    static var previews: some View {
        AddTripCapsule(added: .constant(false))
    }
}
