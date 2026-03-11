//
//  TripRowView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import SwiftUI

struct TripRowView: View {

    let trip: StoredTrip
    let showDate: Bool

    @ObservedObject private var store = FleetStore.shared
    @ObservedObject private var imageStore = FleetImageStore.shared

    private var code: String { trip.carriageCode ?? "Unknown" }

    private var lookup: FleetStore.CarriageLookup? {
        store.findTrain(byCarriage: code)
    }

    var body: some View {
        HStack(spacing: 12) {
            TrainSetImageView(setName: lookup?.set.name ?? "Unknown", size: 42, imageStore: imageStore)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(lookup?.train.name ?? code)
                        .font(.subheadline.bold())

                    Text(code)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Text(lookup?.set.name ?? "Unknown Set")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let loc = trip.locationName, !loc.isEmpty {
                        Text("·")
                            .foregroundStyle(.quaternary)
                        Text(loc)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .lineLimit(1)
            }

            Spacer(minLength: 0)

            if let date = trip.date {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(date.formattedTime())
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    if showDate {
                        Text(date.userFriendlyRelativeString())
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.vertical, 3)
    }
}
