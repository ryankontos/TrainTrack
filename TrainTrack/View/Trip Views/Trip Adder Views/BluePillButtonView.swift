//
//  BluePillButtonView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct BluePillButtonView: View {
    
    @State var label: String
    
    var body: some View {
        
        RoundedRectangle(cornerRadius: 10)
            .frame(height: 50)
            .foregroundColor(.blue)
            .padding(.vertical, 25)
            .padding(.horizontal, 20)
            .overlay(
                Text(label)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            
            )
        
    }
}


