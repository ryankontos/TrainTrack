//
//  ProgressRing.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 5/12/20.
//

import Foundation
import SwiftUI

struct ProgressRing: View {
    
    var progress: Float
    
    let gradient = AngularGradient(
        gradient: Gradient(colors: [.orange, .red]),
        center: .center,
        startAngle: .degrees(0),
        endAngle: .degrees(360))
    
    var body: some View {
        ZStack {
            
            if progress > 0 {
            
            Circle()
                .stroke(lineWidth: 5.5)
                .foregroundColor(.orange)
                .opacity(0.3)
            
        }
                
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round))
                .foregroundColor(.orange)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear)

          
        }
    }
}
