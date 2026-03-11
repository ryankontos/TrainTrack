//
//  CompletedSetAlertView.swift
//  TrainTrack Sydney
//
//  Created by Ryan Kontos on 6/1/2023.
//

import SwiftUI
import ConfettiSwiftUI

struct CompletedSetAlertView: View {
    
    @State var counter = 0
    
    var body: some View {
        VStack {
            
            VStack(alignment: .center, spacing: 3) {
                
                
                Text("Congratulations")
                    .font(.system(size: 42, weight: .medium, design: .default))
                    .multilineTextAlignment(.center)
                
                Text("You've now been on every A Set!")
                    .font(.system(size: 25, weight: .regular, design: .default))
                    .multilineTextAlignment(.center)
                
                
            }
            
            Spacer()
            
            Image("Waratah 2")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 175, height: 175, alignment: .center)
                .clipShape(Circle())
                .confettiCannon(counter: $counter, repetitions: 6, repetitionInterval: 0.5)
                .onAppear() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        counter += 1
                    }
                    
                }
            
          
            Spacer()
            
        }
    }
}

struct CompletedSetAlertView_Previews: PreviewProvider {
    static var previews: some View {
        CompletedSetAlertView()
    }
}
