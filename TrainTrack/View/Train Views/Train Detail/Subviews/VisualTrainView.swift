//
//  VisualTrainView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct VisualTrainView: View {

    let train: FleetTrain
    var highlight: String?
    @ObservedObject private var store = FleetStore.shared

    var body: some View {
        HStack(spacing: 2) {
            ForEach(train.carriages, id: \.self) { code in
                let tripCount = store.stats.carriageTripCounts[code] ?? 0

                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(boxColor(code: code, trips: tripCount))
                    .frame(height: 27)
                    .overlay {
                        if tripCount > 0 {
                            Text("\(tripCount)")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                        }
                    }
            }
        }
    }

    private func boxColor(code: String, trips: Int) -> Color {
        if let h = highlight, code == h {
            return .green.opacity(0.7)
        }
        return trips > 0 ? .accentColor.opacity(0.7) : .gray.opacity(0.3)
    }
}
