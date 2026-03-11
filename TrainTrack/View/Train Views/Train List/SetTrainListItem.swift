//
//  SetTrainListItem.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct SetTrainListItem: View {

    let train: FleetTrain
    let stats: FleetStats.TrainStats?
    let fleetStats: FleetStats

    private var tripCount: Int { stats?.tripCount ?? 0 }
    private var riddenCarriageCount: Int { stats?.carriagesRidden ?? 0 }
    private var totalCarriages: Int { train.carriages.count }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Status circle
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 44, height: 44)

                if tripCount > 0 {
                    Text("\(tripCount)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: train.isRetired ? "clock.arrow.circlepath" : "tram")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(train.name)
                        .font(.system(size: 18, weight: .medium))

                    if train.isRetired {
                        Text(train.status.displayName)
                            .font(.caption2.bold())
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: 8) {
                    Text("\(riddenCarriageCount)/\(totalCarriages) carriages")
                        .foregroundStyle(.secondary)

                    if !train.depot.isEmpty {
                        Text("• \(train.depot)")
                            .foregroundStyle(.tertiary)
                    }
                }
                .font(.subheadline)

                // Mini carriage diagram
                HStack(spacing: 1) {
                    ForEach(train.carriages, id: \.self) { code in
                        let ridden = (fleetStats.carriageTripCounts[code] ?? 0) > 0
                        RoundedRectangle(cornerRadius: 2)
                            .fill(ridden ? Color.green.opacity(0.7) : Color.gray.opacity(0.25))
                            .frame(height: 6)
                    }
                }
                .frame(maxWidth: 150)

                if !train.notes.isEmpty {
                    Text(train.notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .opacity(train.isRetired ? 0.6 : 1.0)
    }

    private var circleColor: Color {
        if train.isRetired { return .gray }
        if tripCount > 0 { return .green }
        return Color.gray.opacity(0.4)
    }
}
