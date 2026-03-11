//
//  NotificationView.swift
//  TrainTrack Sydney
//
//  Created by Ryan on 22/4/2024.
//

import Foundation
import SwiftUI

struct NotificationView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .frame(height: 100)
            .foregroundColor(.blue)
            .overlay(
                Text("Tap to expand")
                    .foregroundColor(.white)
                    .bold()
            )
            .padding()
    }
}
