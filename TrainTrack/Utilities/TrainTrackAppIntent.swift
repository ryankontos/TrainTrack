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

        return .result(dialog: "Logged trip on \(trainName) (\(setName)) — car \(carriageCode)")
    }
}

// MARK: - Trip Stats Intent

struct ViewTripStatsIntent: AppIntent {
    static let title: LocalizedStringResource = "Trip Statistics"
    static let description = IntentDescription("Check how many train trips you've logged.")
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let stats = FleetStore.shared.stats
        let message: String
        if stats.totalTrips == 0 {
            message = "You haven't logged any train trips yet. Open TrainTrack to get started!"
        } else {
            message = "You've logged \(stats.totalTrips) trips across \(stats.trainsRidden) trains and \(stats.setsRidden) fleet types. \(stats.tripsThisWeek) this week."
        }
        return .result(dialog: "\(message)")
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
