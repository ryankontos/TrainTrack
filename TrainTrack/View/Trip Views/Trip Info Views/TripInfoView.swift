//
//  TripInfoView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 21/11/20.
//

import SwiftUI
import MapKit
import CoreData

struct TripInfoView: View {

    let trip: StoredTrip
    @ObservedObject private var store = FleetStore.shared
    @ObservedObject private var imageStore = FleetImageStore.shared

    private var code: String { trip.carriageCode ?? "Unknown" }

    private var lookup: FleetStore.CarriageLookup? {
        store.findTrain(byCarriage: code)
    }

    private var carriageTrips: Int { store.stats.carriageTripCounts[code] ?? 0 }

    private var trainStats: FleetStats.TrainStats? {
        lookup.flatMap { store.stats.trainStats[$0.train.name] }
    }

    // What number trip is this on this carriage?
    private var tripNumber: Int? {
        guard carriageTrips > 0 else { return nil }
        let ctx = TTCloudKit.shared.persistentContainer.viewContext
        let req: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        req.predicate = NSPredicate(format: "carriageCode == %@", code)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \StoredTrip.date, ascending: true)]
        guard let all = try? ctx.fetch(req), let idx = all.firstIndex(of: trip) else { return nil }
        return idx + 1
    }

    var body: some View {
        List {
            // Header
            Section {
                headerView
                    .listRowBackground(Color.clear)
            }

            // Context stats
            if let info = lookup {
                Section {
                    contextStats(info)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            }

            // When & Where
            Section("When") {
                if let date = trip.date {
                    LabeledContent("Date", value: date.formattedDate())
                    LabeledContent("Time", value: date.formattedTime())
                    LabeledContent("Relative", value: date.userFriendlyRelativeString())

                    let dayName = {
                        let fmt = DateFormatter()
                        fmt.dateFormat = "EEEE"
                        return fmt.string(from: date)
                    }()
                    LabeledContent("Day", value: dayName)
                }
            }

            Section("Where") {
                if let locationName = trip.locationName, !locationName.isEmpty {
                    LabeledContent("Location", value: locationName)
                } else {
                    Text("No location recorded")
                        .foregroundStyle(.secondary)
                }

                if trip.latitude != 0, trip.longitude != 0 {
                    LabeledContent("Coordinates", value: String(format: "%.4f, %.4f", trip.latitude, trip.longitude))

                    // Mini map
                    Map(position: .constant(.region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: trip.latitude, longitude: trip.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )))) {
                        Marker(trip.locationName ?? "Trip", coordinate: CLLocationCoordinate2D(latitude: trip.latitude, longitude: trip.longitude))
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            // Train Info
            if let info = lookup {
                Section("Train") {
                    NavigationLink {
                        TrainDetailView(train: info.train, set: info.set)
                    } label: {
                        HStack(spacing: 12) {
                            TrainSetImageView(setName: info.set.name, size: 40, imageStore: imageStore)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(info.train.name)
                                    .font(.subheadline.bold())
                                Text(info.set.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(trainStats?.tripCount ?? 0) trips")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent("Car Position", value: "\(info.position + 1) of \(info.train.carriages.count)")

                    if !info.train.depot.isEmpty {
                        LabeledContent("Depot", value: info.train.depot)
                    }
                    if !info.train.builder.isEmpty {
                        LabeledContent("Builder", value: info.train.builder)
                    }
                    LabeledContent("Status", value: info.train.status.displayName)

                    // Carriage completion for this train
                    let ridden = trainStats?.carriagesRidden ?? 0
                    let total = info.train.carriages.count
                    HStack {
                        Text("Train Completion")
                        Spacer()
                        ProgressView(value: total > 0 ? Double(ridden) / Double(total) : 0)
                            .frame(width: 80)
                            .tint(ridden == total ? .green : .blue)
                        Text("\(ridden)/\(total)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Share
            Section {
                let shareText = buildShareText()
                ShareLink(item: shareText) {
                    Label("Share Trip", systemImage: "square.and.arrow.up")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 16) {
            TrainSetImageView(setName: lookup?.set.name ?? "Unknown", size: 64, imageStore: imageStore)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(code)
                    .font(.title.bold().monospaced())

                Text("\(lookup?.train.name ?? "Unknown") · \(lookup?.set.name ?? "Unknown Set")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let n = tripNumber {
                    Text("Your trip #\(n) on this carriage")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Context Stats

    private func contextStats(_ info: FleetStore.CarriageLookup) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Text("\(carriageTrips)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.blue)
                Text("This Car")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Text("\(trainStats?.tripCount ?? 0)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.green)
                Text("This Train")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Text("\(trainStats?.carriagesRidden ?? 0)/\(info.train.carriages.count)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.orange)
                Text("Cars Ridden")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Text("\(store.stats.setStats[info.set.code]?.tripCount ?? 0)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.purple)
                Text("This Set")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Share

    private func buildShareText() -> String {
        var parts = ["🚂 Trip on \(lookup?.train.name ?? code)"]
        parts.append("Carriage: \(code)")
        if let set = lookup?.set.name { parts.append("Fleet: \(set)") }
        if let date = trip.date { parts.append("Date: \(date.formattedDate()) \(date.formattedTime())") }
        if let loc = trip.locationName, !loc.isEmpty { parts.append("📍 \(loc)") }
        parts.append("Logged with TrainTrack")
        return parts.joined(separator: "\n")
    }
}
