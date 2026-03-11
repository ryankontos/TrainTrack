//
//  TrainTrackAppIntent.swift
//  TrainTrack
//

import AppIntents
import Foundation

// MARK: - Log Trip Intent

struct LogTripIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Train Trip"
    static let description = IntentDescription("Log a trip on a Sydney train by entering the carriage code.")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Carriage Code", description: "The carriage code visible inside the train (e.g. D5101)")
    var carriageCode: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = TripManager()
        let _ = try manager.addTrip(withCode: carriageCode)

        let info = FleetStore.shared.findTrain(byCarriage: carriageCode.uppercased())
        let trainName = info?.train.name ?? "Unknown Train"
        let setName = info?.set.name ?? ""

        return .result(dialog: "Logged trip on \(trainName) (\(setName)) — car \(carriageCode.uppercased())")
    }
}

// MARK: - Trip Stats Intent

struct ViewTripStatsIntent: AppIntent {
    static let title: LocalizedStringResource = "Trip Statistics"
    static let description = IntentDescription("Check how many train trips you've logged and your current stats.")
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let s = FleetStore.shared.stats
        guard s.totalTrips > 0 else {
            return .result(dialog: "You haven't logged any train trips yet. Open TrainTrack to get started!")
        }

        var parts: [String] = []
        parts.append("📊 \(s.totalTrips) total trips across \(s.trainsRidden) trains and \(s.setsRidden) fleet types.")
        if s.tripsToday > 0 { parts.append("Today: \(s.tripsToday) trips.") }
        parts.append("This week: \(s.tripsThisWeek).")
        if s.currentStreak > 1 { parts.append("🔥 \(s.currentStreak)-day streak!") }
        if s.carriagesRidden > 0 { parts.append("\(s.carriagesRidden) unique carriages ridden.") }

        return .result(dialog: "\(parts.joined(separator: " "))")
    }
}

// MARK: - Export Intent

struct ExportTripsIntent: AppIntent {
    static let title: LocalizedStringResource = "Export Trip Data"
    static let description = IntentDescription("Export all your train trip data as a CSV file.")
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        CSVExporter.exportTrips()
        return .result(dialog: "Opening export sheet...")
    }
}

// MARK: - Check Train Intent

struct CheckTrainIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Train Info"
    static let description = IntentDescription("Look up a train or carriage to see its details and your trip history.")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Code", description: "A train name (e.g. D6001) or carriage code (e.g. D5101)")
    var code: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = FleetStore.shared
        let upper = code.uppercased().trimmingCharacters(in: .whitespaces)

        // Try carriage lookup first
        if let lookup = store.findTrain(byCarriage: upper) {
            let trips = store.stats.carriageTripCounts[upper] ?? 0
            let trainTrips = store.stats.trainStats[lookup.train.name]?.tripCount ?? 0
            let pos = lookup.position + 1
            let total = lookup.train.carriages.count
            return .result(dialog: "\(upper) is car \(pos)/\(total) on \(lookup.train.name) (\(lookup.set.name)). You've ridden this carriage \(trips) time\(trips == 1 ? "" : "s"), and this train \(trainTrips) time\(trainTrips == 1 ? "" : "s").")
        }

        // Try train name lookup
        for set in store.fleet.sets {
            if let train = set.trains.first(where: { $0.name.uppercased() == upper }) {
                let stats = store.stats.trainStats[train.name]
                let trips = stats?.tripCount ?? 0
                let cars = stats?.carriagesRidden ?? 0
                return .result(dialog: "\(train.name) is a \(set.name) (\(train.carriages.count) cars, \(train.depot.isEmpty ? "unknown depot" : train.depot)). \(trips) trip\(trips == 1 ? "" : "s") logged, \(cars)/\(train.carriages.count) carriages ridden.")
            }
        }

        return .result(dialog: "Couldn't find '\(upper)' in the fleet. Try a carriage code like D5101 or a train name like D6001.")
    }
}

// MARK: - Fleet Progress Intent

struct FleetProgressIntent: AppIntent {
    static let title: LocalizedStringResource = "Fleet Progress"
    static let description = IntentDescription("See your completion progress across all Sydney train fleet types.")
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = FleetStore.shared
        let s = store.stats

        guard s.totalTrips > 0 else {
            return .result(dialog: "No trips logged yet. Start riding trains to track your fleet progress!")
        }

        let totalTrains = store.fleet.totalTrains
        let totalCarriages = store.fleet.totalCarriages
        let trainPct = totalTrains > 0 ? Int(Double(s.trainsRidden) / Double(totalTrains) * 100) : 0
        let carPct = totalCarriages > 0 ? Int(Double(s.carriagesRidden) / Double(totalCarriages) * 100) : 0

        var lines: [String] = []
        lines.append("🚂 Fleet Progress:")
        lines.append("Sets: \(s.setsRidden)/\(s.totalSets) • Trains: \(s.trainsRidden)/\(totalTrains) (\(trainPct)%) • Carriages: \(s.carriagesRidden)/\(totalCarriages) (\(carPct)%)")

        // Top 3 sets by progress
        let ranked = store.fleet.sets.compactMap { set -> (String, Int, Int)? in
            guard let stats = s.setStats[set.code] else { return nil }
            return (set.name, stats.trainsRidden, stats.totalTrains)
        }.sorted { Double($0.1) / Double(max($0.2, 1)) > Double($1.1) / Double(max($1.2, 1)) }

        for entry in ranked.prefix(3) {
            let pct = entry.2 > 0 ? Int(Double(entry.1) / Double(entry.2) * 100) : 0
            lines.append("  \(entry.0): \(entry.1)/\(entry.2) trains (\(pct)%)")
        }

        return .result(dialog: "\(lines.joined(separator: "\n"))")
    }
}

// MARK: - Recent Trips Intent

struct RecentTripsIntent: AppIntent {
    static let title: LocalizedStringResource = "Recent Trips"
    static let description = IntentDescription("See your most recent train trips.")
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let recent = FleetStore.shared.stats.recentTrips
        guard !recent.isEmpty else {
            return .result(dialog: "No trips logged yet!")
        }

        let lines = recent.prefix(5).map { trip in
            "• \(trip.trainName) (\(trip.carriageCode)) — \(trip.date.userFriendlyRelativeString()), \(trip.date.formattedTime())"
        }

        return .result(dialog: "Recent trips:\n\(lines.joined(separator: "\n"))")
    }
}

// MARK: - App Shortcuts Provider

struct TrainTrackShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogTripIntent(),
            phrases: [
                "Log a trip in \(.applicationName)",
                "Log a train in \(.applicationName)",
                "Add a trip to \(.applicationName)",
                "I'm on a train with \(.applicationName)",
                "Record a trip in \(.applicationName)",
                "New trip in \(.applicationName)",
            ],
            shortTitle: "Log Trip",
            systemImageName: "tram.fill"
        )

        AppShortcut(
            intent: ViewTripStatsIntent(),
            phrases: [
                "How many trips in \(.applicationName)",
                "Trip stats in \(.applicationName)",
                "My train stats in \(.applicationName)",
                "Trip count in \(.applicationName)",
            ],
            shortTitle: "Trip Stats",
            systemImageName: "chart.bar.fill"
        )

        AppShortcut(
            intent: CheckTrainIntent(),
            phrases: [
                "Check a train in \(.applicationName)",
                "Look up a carriage in \(.applicationName)",
                "What train is \(.applicationName)",
            ],
            shortTitle: "Check Train",
            systemImageName: "magnifyingglass"
        )

        AppShortcut(
            intent: FleetProgressIntent(),
            phrases: [
                "Fleet progress in \(.applicationName)",
                "Collection progress in \(.applicationName)",
                "How complete is \(.applicationName)",
            ],
            shortTitle: "Fleet Progress",
            systemImageName: "chart.pie.fill"
        )

        AppShortcut(
            intent: RecentTripsIntent(),
            phrases: [
                "Recent trips in \(.applicationName)",
                "Last trips in \(.applicationName)",
                "Latest trips from \(.applicationName)",
            ],
            shortTitle: "Recent Trips",
            systemImageName: "clock.fill"
        )

        AppShortcut(
            intent: ExportTripsIntent(),
            phrases: [
                "Export trips from \(.applicationName)",
                "Export data from \(.applicationName)",
            ],
            shortTitle: "Export Data",
            systemImageName: "square.and.arrow.up"
        )
    }
}
