//
//  SetsListItem.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import SwiftUI

struct SetsListItem: View {

    let set: FleetSet
    let stats: FleetStats.SetStats?
    @ObservedObject var imageStore: FleetImageStore

    private var trainProgress: Double {
        guard let s = stats, s.totalTrains > 0 else { return 0 }
        return Double(s.trainsRidden) / Double(s.totalTrains)
    }

    private var carriageProgress: Double {
        guard let s = stats, s.totalCarriages > 0 else { return 0 }
        return Double(s.carriagesRidden) / Double(s.totalCarriages)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            TrainSetImageView(setName: set.name, size: 56, imageStore: imageStore)
                .overlay(
                    ProgressRing(progress: Float(trainProgress))
                        .scaleEffect(1.12)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(set.name)
                        .font(.system(size: 20, weight: .semibold))
                        .lineLimit(1)

                    Spacer()

                    if let s = stats, s.tripCount > 0 {
                        Text("\(s.tripCount) trips")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 6) {
                    Text("\(stats?.trainsRidden ?? 0)/\(set.totalTrains) Trains")
                        .font(.subheadline)

                    if trainProgress >= 1.0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: 8) {
                    ProgressView(value: carriageProgress)
                        .tint(carriageProgress >= 1.0 ? .green : .blue)

                    Text("\(Int(carriageProgress * 100))%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                        .frame(width: 32, alignment: .trailing)
                }

                HStack(spacing: 10) {
                    if set.yearIntroduced > 0 {
                        Label("\(String(set.yearIntroduced))", systemImage: "calendar")
                    }

                    if set.carsPerSet > 0 {
                        Label("\(set.carsPerSet)-car", systemImage: "train.side.front.car")
                    }

                    if let lastRidden = stats?.lastRiddenDate {
                        Label(lastRidden.userFriendlyRelativeString(), systemImage: "clock")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
    }
}
