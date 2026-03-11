//
//  SetTrainList.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct SetTrainList: View {

    let fleetSet: FleetSet

    @ObservedObject private var store = FleetStore.shared
    @ObservedObject private var imageStore = FleetImageStore.shared
    @State private var filterMode: FilterMode = .all
    @State private var showingSheet = false
    @State private var searchText = ""
    @State private var sortMode: SortMode = .name

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case ridden = "Ridden"
        case unridden = "Not Ridden"
        case retired = "Retired"
    }

    enum SortMode: String, CaseIterable {
        case name = "Name"
        case trips = "Most Trips"
        case completion = "Completion"
    }

    private var trains: [FleetTrain] {
        var filtered = fleetSet.trains

        switch filterMode {
        case .all: break
        case .ridden:
            filtered = filtered.filter { (store.stats.trainStats[$0.name]?.tripCount ?? 0) > 0 }
        case .unridden:
            filtered = filtered.filter { (store.stats.trainStats[$0.name]?.tripCount ?? 0) == 0 }
        case .retired:
            filtered = filtered.filter { $0.isRetired }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.depot.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortMode {
        case .name:
            break // already sorted by name
        case .trips:
            filtered.sort { (store.stats.trainStats[$0.name]?.tripCount ?? 0) > (store.stats.trainStats[$1.name]?.tripCount ?? 0) }
        case .completion:
            filtered.sort {
                let a = store.stats.trainStats[$0.name]
                let b = store.stats.trainStats[$1.name]
                let pctA = $0.carriages.isEmpty ? 0 : Double(a?.carriagesRidden ?? 0) / Double($0.carriages.count)
                let pctB = $1.carriages.isEmpty ? 0 : Double(b?.carriagesRidden ?? 0) / Double($1.carriages.count)
                return pctA > pctB
            }
        }

        return filtered
    }

    private var hasRetired: Bool {
        fleetSet.trains.contains { $0.isRetired }
    }

    var body: some View {
        List {
            Section {
                SetInfoHeader(fleetSet: fleetSet, stats: store.stats.setStats[fleetSet.code], imageStore: imageStore)
            }

            Section {
                ForEach(trains) { train in
                    NavigationLink {
                        TrainDetailView(train: train, set: fleetSet)
                    } label: {
                        SetTrainListItem(
                            train: train,
                            stats: store.stats.trainStats[train.name],
                            fleetStats: store.stats
                        )
                    }
                }
            } header: {
                HStack {
                    Text("\(trains.count) Trains")
                    Spacer()
                    if filterMode != .all || sortMode != .name {
                        Button("Reset") {
                            filterMode = .all
                            sortMode = .name
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search trains")
        .navigationTitle(fleetSet.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Section("Filter") {
                        ForEach(FilterMode.allCases, id: \.self) { mode in
                            if mode != .retired || hasRetired {
                                Button {
                                    filterMode = mode
                                } label: {
                                    if filterMode == mode {
                                        Label(mode.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(mode.rawValue)
                                    }
                                }
                            }
                        }
                    }

                    Section("Sort") {
                        ForEach(SortMode.allCases, id: \.self) { mode in
                            Button {
                                sortMode = mode
                            } label: {
                                if sortMode == mode {
                                    Label(mode.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(mode.rawValue)
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: (filterMode == .all && sortMode == .name) ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
            }
        }
    }
}

struct SetInfoHeader: View {
    let fleetSet: FleetSet
    let stats: FleetStats.SetStats?
    @ObservedObject var imageStore: FleetImageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                TrainSetImageView(setName: fleetSet.name, size: 64, imageStore: imageStore)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(fleetSet.name)
                        .font(.title2.bold())

                    Text(fleetSet.networkLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !fleetSet.defaultBuilder.isEmpty {
                        Text(fleetSet.defaultBuilder)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }
                }
            }

            // Stats row
            HStack(spacing: 0) {
                StatPill(label: "Trains", value: "\(stats?.trainsRidden ?? 0)/\(fleetSet.totalTrains)")
                StatPill(label: "Carriages", value: "\(stats?.carriagesRidden ?? 0)/\(fleetSet.totalCarriages)")
                StatPill(label: "Trips", value: "\(stats?.tripCount ?? 0)")
                StatPill(label: "Since", value: "\(fleetSet.yearIntroduced)")
            }

            // Additional info
            HStack(spacing: 16) {
                if fleetSet.retiredTrains > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("\(fleetSet.retiredTrains) retired")
                    }
                    .foregroundStyle(.orange)
                }

                HStack(spacing: 3) {
                    Image(systemName: "tram")
                    Text("\(fleetSet.activeTrains) active")
                }
                .foregroundStyle(.green)

                if !fleetSet.uniqueDepots.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "building.2")
                        Text(fleetSet.uniqueDepots.joined(separator: ", "))
                            .lineLimit(1)
                    }
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .listRowBackground(Color.clear)
    }
}

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
