//
//  SetTrainList.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct SetTrainList: View {

    let set: FleetSet

    @ObservedObject private var store = FleetStore.shared
    @ObservedObject private var imageStore = FleetImageStore.shared
    @State private var filterMode: FilterMode = .all
    @State private var showingSheet = false
    @State private var searchText = ""

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case ridden = "Ridden"
        case unridden = "Not Ridden"
        case retired = "Retired"
    }

    private var trains: [FleetTrain] {
        var filtered = set.trains

        switch filterMode {
        case .all:
            break
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
            }
        }

        return filtered
    }

    private var hasRetired: Bool {
        set.trains.contains { $0.isRetired }
    }

    var body: some View {
        List {
            Section {
                SetInfoHeader(set: set, stats: store.stats.setStats[set.code], imageStore: imageStore)
            }

            Section {
                ForEach(trains) { train in
                    NavigationLink {
                        TrainDetailView(train: train, set: set)
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
                    if filterMode != .all {
                        Button("Clear") { filterMode = .all }
                            .font(.caption)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search trains")
        .navigationTitle(set.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
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
                } label: {
                    Image(systemName: filterMode == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
            }
        }
    }
}

struct SetInfoHeader: View {
    let set: FleetSet
    let stats: FleetStats.SetStats?
    @ObservedObject var imageStore: FleetImageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                TrainSetImageView(setName: set.name, size: 64, imageStore: imageStore)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(set.name)
                        .font(.title2.bold())

                    if !set.defaultBuilder.isEmpty {
                        Text(set.defaultBuilder)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }

            HStack(spacing: 16) {
                StatPill(label: "Trains", value: "\(stats?.trainsRidden ?? 0)/\(set.totalTrains)")
                StatPill(label: "Carriages", value: "\(stats?.carriagesRidden ?? 0)/\(set.totalCarriages)")
                StatPill(label: "Trips", value: "\(stats?.tripCount ?? 0)")
                if set.yearIntroduced > 0 {
                    StatPill(label: "Since", value: "\(set.yearIntroduced)")
                }
            }
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
