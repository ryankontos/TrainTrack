//
//  TripInfoView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 21/11/20.
//

import SwiftUI
import MapKit

struct TripInfoView: View {

    let trip: StoredTrip
    @ObservedObject private var store = FleetStore.shared
    @ObservedObject private var imageStore = FleetImageStore.shared

    private var code: String { trip.carriageCode ?? "Unknown" }

    private var lookup: FleetStore.CarriageLookup? {
        store.findTrain(byCarriage: code)
    }

    var body: some View {
        List {
            // Header
            Section {
                HStack(spacing: 16) {
                    TrainSetImageView(setName: lookup?.set.name ?? "Unknown", size: 60, imageStore: imageStore)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(code)
                            .font(.title2.bold().monospaced())

                        Text("\(lookup?.train.name ?? "Unknown") • \(lookup?.set.name ?? "Unknown Set")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(Color.clear)
            }

            // When
            Section("When") {
                if let date = trip.date {
                    LabeledContent("Date", value: date.formattedDate())
                    LabeledContent("Time", value: date.formattedTime())
                    LabeledContent("Relative", value: date.userFriendlyRelativeString())
                }
            }

            // Where
            Section("Where") {
                if let locationName = trip.locationName, !locationName.isEmpty {
                    LabeledContent("Location", value: locationName)
                } else {
                    Text("No location recorded")
                        .foregroundStyle(.secondary)
                }

                if trip.latitude != 0, trip.longitude != 0 {
                    LabeledContent("Coordinates", value: String(format: "%.4f, %.4f", trip.latitude, trip.longitude))
                }
            }

            // Train Info
            if let info = lookup {
                Section("Train Info") {
                    LabeledContent("Train", value: info.train.name)
                    LabeledContent("Set Type", value: info.set.name)

                    if !info.train.depot.isEmpty {
                        LabeledContent("Depot", value: info.train.depot)
                    }

                    if !info.train.builder.isEmpty {
                        LabeledContent("Builder", value: info.train.builder)
                    }

                    LabeledContent("Status", value: info.train.status.displayName)

                    LabeledContent("Car Position", value: "\(info.position + 1) of \(info.train.carriages.count)")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
