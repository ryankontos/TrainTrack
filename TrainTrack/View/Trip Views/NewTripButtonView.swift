//
//  NewTripButtonView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct NewTripButtonView: View {
    
    @Environment (\.colorScheme) var colorScheme:ColorScheme
    
    @Binding var toggled: Bool
    
    var op: Double {
        
        if colorScheme == .light {
            return 0.09
        } else {
            return 0.29
        }
        
    }
    
    var body: some View {
        
        Button(action: {toggled.toggle()}) {
            
            RoundedRectangle(cornerRadius: 13)
                .frame(height: 51)
                .foregroundColor(Color(UIColor.systemBlue).opacity(op))
                .overlay(HStack(spacing: 6) {
                    
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(UIColor.systemBlue))
                        .font(.system(size: 21, weight: .regular, design: .default))
                    
                    Text("New Trip")
                        .foregroundColor(Color(UIColor.systemBlue))
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        
                    
                }).textCase(.none)
            
            
        }
        
        
        
    }
}
struct NewTripButtonView_Previews: PreviewProvider {
    static var previews: some View {
        NewTripButtonView(toggled: .constant(true))
    }
}
