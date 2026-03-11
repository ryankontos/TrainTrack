//
//  AllTripsView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import SwiftUI
import CoreData

struct AllTripsView: View {

    @ObservedObject private var store = FleetStore.shared
    @ObservedObject private var imageStore = FleetImageStore.shared
    @FetchRequest private var trips: FetchedResults<StoredTrip>
    @State private var searchText = ""
    @State private var filterSet: String? = nil
    @State private var sortNewest = true

    init() {
        let request: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredTrip.date, ascending: false)]
        _trips = FetchRequest(fetchRequest: request, animation: .default)
    }

    private var filteredTrips: [StoredTrip] {
        let archiveId = TTCloudKit.shared.activeArchiveId
        var result = trips.filter { trip in
            if let archiveId {
                return trip.archiveId == archiveId
            } else {
                return trip.archiveId == nil
            }
        }

        if !searchText.isEmpty {
            result = result.filter {
                ($0.carriageCode ?? "").localizedCaseInsensitiveContains(searchText)
                    || ($0.locationName ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        if let setFilter = filterSet {
            result = result.filter { trip in
                guard let code = trip.carriageCode else { return false }
                return store.findTrain(byCarriage: code)?.set.code == setFilter
            }
        }

        if !sortNewest {
            result = result.reversed()
        }

        return result
    }

    private var tripsByDay: [(date: Date, trips: [StoredTrip])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTrips) { trip -> Date in
            guard let date = trip.date else { return .distantPast }
            return calendar.startOfDay(for: date)
        }
        return grouped
            .map { (date: $0.key, trips: $0.value) }
            .sorted { sortNewest ? $0.date > $1.date : $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                // Stats header
                if !filteredTrips.isEmpty {
                    Section {
                        statsHeader
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }
                }

                // Trip list
                ForEach(tripsByDay, id: \.date) { day in
                    Section {
                        ForEach(day.trips, id: \.objectID) { trip in
                            NavigationLink {
                                TripInfoView(trip: trip)
                            } label: {
                                TripRowView(trip: trip, showDate: false)
                            }
                        }
                        .onDelete { offsets in
                            deleteTrips(offsets: offsets, from: day.trips)
                        }
                    } header: {
                        HStack {
                            Text(day.date.userFriendlyRelativeString())
                            Spacer()
                            Text("\(day.trips.count)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search trips")
            .overlay {
                if filteredTrips.isEmpty && searchText.isEmpty && filterSet == nil {
                    ContentUnavailableView("No Trips Yet", systemImage: "tram",
                        description: Text("Tap + to log your first trip!"))
                } else if filteredTrips.isEmpty {
                    ContentUnavailableView.search
                }
            }
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // Sort
                        Section("Sort") {
                            Button {
                                sortNewest = true
                            } label: {
                                Label("Newest First", systemImage: sortNewest ? "checkmark" : "")
                            }
                            Button {
                                sortNewest = false
                            } label: {
                                Label("Oldest First", systemImage: !sortNewest ? "checkmark" : "")
                            }
                        }

                        // Filter by set
                        Section("Filter by Set") {
                            Button {
                                filterSet = nil
                            } label: {
                                Label("All Sets", systemImage: filterSet == nil ? "checkmark" : "")
                            }
                            ForEach(store.fleet.sets) { set in
                                let count = store.stats.setStats[set.code]?.tripCount ?? 0
                                if count > 0 {
                                    Button {
                                        filterSet = set.code
                                    } label: {
                                        Label("\(set.name) (\(count))", systemImage: filterSet == set.code ? "checkmark" : "")
                                    }
                                }
                            }
                        }

                        Section {
                            Button {
                                CSVExporter.exportTrips()
                            } label: {
                                Label("Export as CSV", systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: filterSet != nil ? "line.3.horizontal.decrease.circle.fill" : "ellipsis.circle")
                    }
                }
            }
        }
        .environment(\.managedObjectContext, TTCloudKit.shared.persistentContainer.viewContext)
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        let s = store.stats
        return HStack(spacing: 0) {
            StatColumn(value: "\(filteredTrips.count)", label: "Total", color: .blue)
            StatColumn(value: "\(s.tripsToday)", label: "Today", color: .green)
            StatColumn(value: "\(s.tripsThisWeek)", label: "Week", color: .orange)

            let uniqueTrains = Set(filteredTrips.compactMap { trip in
                trip.carriageCode.flatMap { store.findTrain(byCarriage: $0)?.train.name }
            }).count
            StatColumn(value: "\(uniqueTrains)", label: "Trains", color: .purple)
        }
        .padding(.vertical, 8)
    }

    private func deleteTrips(offsets: IndexSet, from dayTrips: [StoredTrip]) {
        let manager = TripManager()
        let toDelete = offsets.map { dayTrips[$0] }
        manager.deleteTrips(toDelete)
    }
}

private struct StatColumn: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
