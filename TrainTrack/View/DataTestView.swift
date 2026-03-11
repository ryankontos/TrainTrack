//
//  DataTestView.swift
//  TrainTrack Sydney
//
//  Created by Ryan on 11/4/2024.
//

import SwiftUI

struct DataTestView: View {

    @ObservedObject private var store = FleetStore.shared

    var body: some View {
        List {
            ForEach(store.fleet.sets) { set in
                Section(set.name) {
                    ForEach(set.trains) { train in
                        Text("\(train.name) — \(train.carriages.count) cars")
                    }
                }
            }
        }
        .navigationTitle("Fleet Data Test")
    }
}

#Preview {
    DataTestView()
}
