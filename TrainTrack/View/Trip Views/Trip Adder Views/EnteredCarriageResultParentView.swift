//
//  EnteredCarriageResultParentView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct EnteredCarriageResultParentView: View {

    @Binding var showingSheet: Bool
    var carriage: String

    var body: some View {
        if let lookup = FleetStore.shared.findTrain(byCarriage: carriage) {
            TrainDetailView(train: lookup.train, set: lookup.set)
        } else {
            ContentUnavailableView {
                Label("Invalid Carriage Code", systemImage: "nosign")
            } description: {
                Text("'\(carriage)' doesn't match any known carriage.")
            }
        }
    }
}
