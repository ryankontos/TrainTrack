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
                    Section {
                        ForEach(filteredSets) { set in
                            NavigationLink {
                                SetTrainList(set: set)
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
        }
    }
}
