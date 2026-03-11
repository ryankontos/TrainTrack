//
//  ContentView.swift
//  TrainTrack Watch WatchKit Extension
//
//  Created by Ryan Kontos on 24/1/2022.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tram.fill")
                .font(.largeTitle)
                .foregroundStyle(.blue)

            Text("TrainTrack")
                .font(.headline)

            Text("Open on iPhone to log trips")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
