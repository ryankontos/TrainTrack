//
//  SetsList.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import SwiftUI

struct SetsList: View {

    @ObservedObject private var store = FleetStore.shared
    @ObservedObject private var imageStore = FleetImageStore.shared
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if store.fleet.sets.isEmpty {
                    if store.isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading fleet data...")
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        ContentUnavailableView("No Sets", systemImage: "tram.fill",
                            description: Text("Fleet data couldn't be loaded. Pull to refresh."))
                            .listRowBackground(Color.clear)
                    }
                } else {
                    // Fleet summary
                    Section {
                        fleetSummary
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }

                    Section {
                        ForEach(filteredSets) { set in
                            NavigationLink {
                                SetTrainList(fleetSet: set)
                            } label: {
                                SetsListItem(
                                    set: set,
                                    stats: store.stats.setStats[set.code],
                                    imageStore: imageStore
                                )
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Trains")
            .searchable(text: $searchText, prompt: "Search sets")
            .refreshable {
                store.load()
            }
        }
    }

    private var filteredSets: [FleetSet] {
        if searchText.isEmpty {
            return store.fleet.sets
        }
        return store.fleet.sets.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.code.localizedCaseInsensitiveContains(searchText)
                || $0.defaultBuilder.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var fleetSummary: some View {
        let f = store.fleet
        let s = store.stats
        return HStack(spacing: 0) {
            VStack(spacing: 2) {
                Text("\(f.sets.count)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                Text("Types")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Text("\(f.totalTrains)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                Text("Trains")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Text("\(s.trainsRidden)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                Text("Ridden")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                let pct = f.totalTrains > 0 ? Int(Double(s.trainsRidden) / Double(f.totalTrains) * 100) : 0
                Text("\(pct)%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.purple)
                Text("Complete")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
    }
}
