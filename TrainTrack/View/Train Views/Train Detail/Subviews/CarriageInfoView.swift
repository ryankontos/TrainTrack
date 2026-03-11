//
//  CarriageInfoView.swift
//  TrainTrack Sydney
//
//  Created by Ryan Kontos on 14/10/2022.
//

import SwiftUI

struct CarriageInfoView: View {

    let train: FleetTrain
    var highlightCode: String?
    @Binding var sheet: Bool
    @ObservedObject private var store = FleetStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(Array(train.carriages.enumerated()), id: \.element) { index, code in
                    let tripCount = store.stats.carriageTripCounts[code] ?? 0

                    HStack {
                        RoundedCornersShape(corners: corners(for: index), radius: 6)
                            .foregroundColor(tripCount > 0 ? .accentColor.opacity(0.7) : .gray.opacity(0.3))
                            .frame(width: 25, height: 60)
                            .overlay {
                                if code == highlightCode {
                                    Image(systemName: "arrow.forward")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.leading, -50)
                                }
                            }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(code)
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))

                            if tripCount > 0 {
                                Text("\(tripCount) trips")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(width: 200)
                }
            }
            .padding(.vertical)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { sheet = false }
            }
        }
    }

    private func corners(for index: Int) -> UIRectCorner {
        if index == 0 { return [.topLeft, .topRight] }
        if index == train.carriages.count - 1 { return [.bottomLeft, .bottomRight] }
        return []
    }
}
