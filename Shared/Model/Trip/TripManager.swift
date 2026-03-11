//
//  TripManager.swift
//  TrainTrack Sydney
//
//  Created by Ryan on 12/4/2024.
//

import Foundation
import CoreData
import AppIntents
import os.log

private let logger = Logger(subsystem: "com.ryankontos.traintrack", category: "TripManager")

enum TripError: LocalizedError {
    case emptyCode
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .emptyCode: return "Carriage code cannot be empty."
        case .saveFailed: return "Failed to save trip."
        }
    }
}

final class TripManager {

    private var context: NSManagedObjectContext {
        TTCloudKit.shared.persistentContainer.viewContext
    }

    @discardableResult
    func addTrip(withCode code: String) throws -> StoredTrip {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { throw TripError.emptyCode }

        let trip = StoredTrip(context: context)
        trip.carriageCode = trimmed
        trip.date = Date()

        // Archive
        if let archiveId = TTCloudKit.shared.activeArchiveId {
            trip.archiveId = archiveId
        }

        // Location
        if let location = LocationManager.shared?.lastLocation {
            trip.latitude = location.coordinate.latitude
            trip.longitude = location.coordinate.longitude
        }
        if let name = LocationManager.shared?.currentLocationName {
            trip.locationName = name
        }

        guard TTCloudKit.shared.saveContext() else {
            context.rollback()
            throw TripError.saveFailed
        }

        logger.info("Trip saved: \(trimmed)")
        NotificationCenter.default.post(name: .tripAdded, object: nil)

        // Donate intent for proactive Siri suggestions
        Task {
            let intent = LogTripIntent()
            intent.carriageCode = trimmed
            try? await intent.donate()
        }

        return trip
    }

    func deleteTrip(_ trip: StoredTrip) {
        context.delete(trip)
        TTCloudKit.shared.saveContext()
    }

    func deleteTrips(_ trips: [StoredTrip]) {
        trips.forEach { context.delete($0) }
        TTCloudKit.shared.saveContext()
    }
}
