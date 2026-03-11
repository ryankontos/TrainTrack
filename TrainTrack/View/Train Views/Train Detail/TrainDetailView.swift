//
//  TrainDetailView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI
import CoreData

struct TrainDetailView: View {

    let train: FleetTrain
    let set: FleetSet

    @ObservedObject private var store = FleetStore.shared
    @ObservedObject private var imageStore = FleetImageStore.shared

    private var trainStats: FleetStats.TrainStats? {
        store.stats.trainStats[train.name]
    }

    private var trips: [StoredTrip] {
        let context = TTCloudKit.shared.persistentContainer.viewContext
        let request: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        let codes = train.carriages
        guard !codes.isEmpty else { return [] }
        request.predicate = NSPredicate(format: "carriageCode IN %@", codes)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredTrip.date, ascending: false)]
        request.fetchLimit = 100
        return (try? context.fetch(request)) ?? []
    }

    var body: some View {
        List {
            // Header
            Section {
                headerView
                    .listRowBackground(Color.clear)
            }

            // Visual carriage diagram
            if !train.carriages.isEmpty {
                Section("Carriages") {
                    carriageDiagram
                        .listRowBackground(Color.clear)

                    ForEach(Array(train.carriages.enumerated()), id: \.element) { index, code in
                        carriageRow(code: code, position: index)
                    }
                }
            }

            // Details
            Section("Details") {
                if !train.depot.isEmpty {
                    LabeledContent("Depot", value: train.depot)
                }
                if !train.builder.isEmpty {
                    LabeledContent("Builder", value: train.builder)
                }
                LabeledContent("Status", value: train.status.displayName)
                LabeledContent("Set", value: set.name)
                LabeledContent("Cars", value: "\(train.carriages.count)")
                if !train.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(train.notes)
                            .font(.subheadline)
                    }
                }
            }

            // Trips
            if !trips.isEmpty {
                Section("Trips (\(trips.count))") {
                    ForEach(trips.prefix(50), id: \.objectID) { trip in
                        StoredTripRow(trip: trip, showDate: true)
                    }

                    if trips.count > 50 {
                        Text("+ \(trips.count - 50) more trips")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(train.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 16) {
            TrainSetImageView(setName: set.name, size: 80, imageStore: imageStore)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(train.name)
                        .font(.title2.bold())

                    if train.isRetired {
                        Text(train.status.displayName)
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }
                }

                Text(set.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                overviewText
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
    }

    private var overviewText: some View {
        Group {
            if let s = trainStats, s.tripCount > 0 {
                Text("\(s.tripCount) trips • \(s.carriagesRidden)/\(train.carriages.count) carriages ridden")
            } else {
                Text("No trips logged on this train yet.")
            }
        }
    }

    // MARK: - Carriage Diagram

    private var carriageDiagram: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 3) {
                ForEach(train.carriages, id: \.self) { code in
                    let tripCount = store.stats.carriageTripCounts[code] ?? 0
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(tripCount > 0 ? Color.green.opacity(0.7) : Color.gray.opacity(0.25))
                            .frame(width: 44, height: 28)
                            .overlay {
                                if tripCount > 0 {
                                    Text("\(tripCount)")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                }
                            }

                        Text(code)
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Carriage Row

    private func carriageRow(code: String, position: Int) -> some View {
        let tripCount = store.stats.carriageTripCounts[code] ?? 0
        return HStack {
            Circle()
                .fill(tripCount > 0 ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)

            Text(code)
                .font(.subheadline.monospaced())

            Spacer()

            if tripCount > 0 {
                Text("\(tripCount) trips")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Not ridden")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// Reusable StoredTrip row for trip lists
struct StoredTripRow: View {
    let trip: StoredTrip
    let showDate: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: "tram.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(trip.carriageCode ?? "Unknown")
                    .font(.subheadline.bold().monospaced())

                if let loc = trip.locationName, !loc.isEmpty {
                    Text(loc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let date = trip.date {
                VStack(alignment: .trailing, spacing: 2) {
                    if showDate {
                        Text(date.formattedDate())
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Text(date.formattedTime())
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
