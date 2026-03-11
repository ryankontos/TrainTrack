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
    @FetchRequest private var trips: FetchedResults<StoredTrip>
    @State private var searchText = ""

    init() {
        let request: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredTrip.date, ascending: false)]
        // We filter by archive in the view using the store's activeArchiveId
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
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(tripsByDay, id: \.date) { day in
                    Section(day.date.userFriendlyRelativeString()) {
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
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search trips")
            .overlay {
                if filteredTrips.isEmpty {
                    ContentUnavailableView("No Trips Yet", systemImage: "tram",
                        description: Text("Tap + to log your first trip!"))
                }
            }
            .navigationTitle("Trips (\(filteredTrips.count))")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            CSVExporter.exportTrips()
                        } label: {
                            Label("Export as CSV", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .environment(\.managedObjectContext, TTCloudKit.shared.persistentContainer.viewContext)
    }

    private func deleteTrips(offsets: IndexSet, from dayTrips: [StoredTrip]) {
        let manager = TripManager()
        let toDelete = offsets.map { dayTrips[$0] }
        manager.deleteTrips(toDelete)
    }
}
