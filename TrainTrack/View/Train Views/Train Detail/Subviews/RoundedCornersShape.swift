//
//  RoundedCornersShape.swift
//  TrainTrack Sydney
//
//  Created by Ryan Kontos on 24/10/2022.
//

import SwiftUI

struct RoundedCornersShape: Shape {
    let corners: UIRectCorner
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
