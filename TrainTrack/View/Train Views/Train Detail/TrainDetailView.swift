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

    private var completionPct: Double {
        guard let s = trainStats, train.carriages.count > 0 else { return 0 }
        return Double(s.carriagesRidden) / Double(train.carriages.count)
    }

    var body: some View {
        List {
            // Header
            Section {
                headerView
                    .listRowBackground(Color.clear)
            }

            // Stats overview
            if let s = trainStats, s.tripCount > 0 {
                Section {
                    statsGrid(s)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            }

            // Visual carriage diagram
            if !train.carriages.isEmpty {
                Section("Carriages (\(trainStats?.carriagesRidden ?? 0)/\(train.carriages.count) ridden)") {
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
                LabeledContent("Status") {
                    HStack(spacing: 4) {
                        Image(systemName: train.status.icon)
                            .font(.caption)
                        Text(train.status.displayName)
                    }
                    .foregroundStyle(train.isRetired ? .orange : .green)
                }
                LabeledContent("Set", value: set.name)
                LabeledContent("Network", value: set.networkLine)
                LabeledContent("Cars", value: "\(train.carriages.count)")
                LabeledContent("Introduced", value: "\(set.yearIntroduced)")
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

            // Trip timeline
            if !trips.isEmpty {
                Section("Trip History (\(trips.count))") {
                    // Trip frequency info
                    if let first = trainStats?.firstRiddenDate, let last = trainStats?.lastRiddenDate {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("First ridden")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(first.formattedDate())
                                    .font(.caption)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("Last ridden")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(last.formattedDate())
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    ForEach(trips.prefix(50), id: \.objectID) { trip in
                        NavigationLink {
                            TripInfoView(trip: trip)
                        } label: {
                            StoredTripRow(trip: trip, showDate: true)
                        }
                    }

                    if trips.count > 50 {
                        Text("+ \(trips.count - 50) more trips")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Share
            Section {
                let text = "🚂 \(train.name) (\(set.name))\n\(trainStats?.tripCount ?? 0) trips, \(trainStats?.carriagesRidden ?? 0)/\(train.carriages.count) carriages ridden\nTracked with TrainTrack"
                ShareLink(item: text) {
                    Label("Share Train", systemImage: "square.and.arrow.up")
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

                // Completion bar
                HStack(spacing: 8) {
                    ProgressView(value: completionPct)
                        .tint(completionPct >= 1.0 ? .green : .blue)
                    Text("\(Int(completionPct * 100))%")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(completionPct >= 1.0 ? .green : .secondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Stats Grid

    private func statsGrid(_ s: FleetStats.TrainStats) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Text("\(s.tripCount)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.blue)
                Text("Trips")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Text("\(s.carriagesRidden)/\(s.totalCarriages)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.green)
                Text("Carriages")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                let uniqueLocations = Set(trips.compactMap(\.locationName).filter { !$0.isEmpty }).count
                Text("\(uniqueLocations)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.orange)
                Text("Locations")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                let uniqueDays = Set(trips.compactMap(\.date).map { Calendar.current.startOfDay(for: $0) }).count
                Text("\(uniqueDays)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.purple)
                Text("Days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
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

            Text("Car \(position + 1)")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer()

            if tripCount > 0 {
                Text("\(tripCount) trip\(tripCount == 1 ? "" : "s")")
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
