//
//  ArchiveManager.swift
//  TrainTrack Sydney
//
//  Created by TrainTrack on 2026.
//

import Foundation
import CoreData
import os.log

private let logger = Logger(subsystem: "com.ryankontos.traintrack", category: "ArchiveManager")

/// Manages trip archives — lets users freeze their trip history and start fresh.
@MainActor
final class ArchiveManager: ObservableObject {

    static let shared = ArchiveManager()

    @Published private(set) var archives: [ArchiveInfo] = []
    @Published private(set) var activeArchive: ArchiveInfo?

    struct ArchiveInfo: Identifiable, Hashable {
        let id: UUID
        let name: String
        let createdDate: Date
        let isActive: Bool
        let tripCount: Int
    }

    private var context: NSManagedObjectContext {
        TTCloudKit.shared.persistentContainer.viewContext
    }

    func reload() {
        let request: NSFetchRequest<ArchiveRecord> = ArchiveRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ArchiveRecord.createdDate, ascending: false)]

        guard let records = try? context.fetch(request) else { return }

        archives = records.compactMap { record in
            guard let id = record.id, let name = record.name else { return nil }
            let tripCount = countTrips(for: id)
            return ArchiveInfo(
                id: id,
                name: name,
                createdDate: record.createdDate ?? Date.distantPast,
                isActive: record.isActive,
                tripCount: tripCount
            )
        }

        // Count "default" (nil archiveId) trips
        let defaultCount = countTrips(for: nil)
        let defaultArchive = ArchiveInfo(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            name: "Original Trips",
            createdDate: .distantPast,
            isActive: TTCloudKit.shared.activeArchiveId == nil,
            tripCount: defaultCount
        )

        archives.insert(defaultArchive, at: 0)
        activeArchive = archives.first(where: \.isActive)
    }

    /// Creates a new archive and makes it active. All future trips go here.
    @discardableResult
    func createArchive(name: String) -> UUID {
        let id = UUID()

        // Deactivate all existing archives
        let allRequest: NSFetchRequest<ArchiveRecord> = ArchiveRecord.fetchRequest()
        allRequest.predicate = NSPredicate(format: "isActive == YES")
        if let activeRecords = try? context.fetch(allRequest) {
            activeRecords.forEach { $0.isActive = false }
        }

        let record = ArchiveRecord(context: context)
        record.id = id
        record.name = name
        record.createdDate = Date()
        record.isActive = true

        TTCloudKit.shared.saveContext()
        TTCloudKit.shared.setActiveArchive(id)

        logger.info("Created archive '\(name)' with id \(id)")
        reload()
        return id
    }

    /// Switches the active archive. Pass nil to switch to the default (unarchived) view.
    func switchToArchive(_ archiveId: UUID?) {
        let isDefault = archiveId == UUID(uuidString: "00000000-0000-0000-0000-000000000000")
        TTCloudKit.shared.setActiveArchive(isDefault ? nil : archiveId)
        reload()

        NotificationCenter.default.post(name: .archiveChanged, object: nil)
        logger.info("Switched to archive \(archiveId?.uuidString ?? "default")")
    }

    /// Renames an existing archive.
    func renameArchive(_ archiveId: UUID, to newName: String) {
        let request: NSFetchRequest<ArchiveRecord> = ArchiveRecord.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", archiveId as CVarArg)
        request.fetchLimit = 1

        if let record = try? context.fetch(request).first {
            record.name = newName
            TTCloudKit.shared.saveContext()
            reload()
        }
    }

    /// Deletes an archive record. Does NOT delete trips — they become "orphaned" (still accessible).
    func deleteArchive(_ archiveId: UUID) {
        let request: NSFetchRequest<ArchiveRecord> = ArchiveRecord.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", archiveId as CVarArg)
        request.fetchLimit = 1

        if let record = try? context.fetch(request).first {
            let wasActive = record.isActive
            context.delete(record)
            TTCloudKit.shared.saveContext()

            if wasActive {
                TTCloudKit.shared.setActiveArchive(nil)
            }
            reload()
        }
    }

    private func countTrips(for archiveId: UUID?) -> Int {
        let request: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        if let archiveId {
            request.predicate = NSPredicate(format: "archiveId == %@", archiveId as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "archiveId == nil")
        }
        return (try? context.count(for: request)) ?? 0
    }
}

extension Notification.Name {
    static let archiveChanged = Notification.Name("archiveChanged")
    static let tripAdded = Notification.Name("tripAdded")
}
