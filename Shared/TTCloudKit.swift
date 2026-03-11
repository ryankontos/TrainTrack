//
//  TTCloudKit.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 24/1/2022.
//

import Foundation
import CloudKit
import CoreData
import os.log

private let logger = Logger(subsystem: "com.ryankontos.traintrack", category: "CoreData")

final class TTCloudKit {

    static var shared: TTCloudKit!

    let persistentContainer: NSPersistentCloudKitContainer

    /// The currently active archive ID. Nil means "default" (all legacy trips).
    @Published private(set) var activeArchiveId: UUID?

    init() {
        persistentContainer = TTCloudKit.makeCloudContainer()
        loadActiveArchive()
    }

    // MARK: - Container Setup

    private static func makeCloudContainer() -> NSPersistentCloudKitContainer {
        let container = NSPersistentCloudKitContainer(name: "TrainTrack")

        if let desc = container.persistentStoreDescriptions.first {
            desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            desc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            desc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.ryankontos.traintrack"
            )
        }

        container.loadPersistentStores { description, error in
            if let error {
                logger.fault("Failed to load cloud store: \(error.localizedDescription)")
            } else {
                logger.info("Cloud store loaded: \(description.url?.lastPathComponent ?? "?")")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.name = "CloudViewContext"

        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            logger.error("Failed to pin viewContext: \(error.localizedDescription)")
        }

        return container
    }

    // MARK: - Saving

    @discardableResult
    func saveContext() -> Bool {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return true }

        do {
            try context.save()
            return true
        } catch {
            logger.error("Save failed: \(error.localizedDescription)")
            context.rollback()
            return false
        }
    }

    // MARK: - Archive Management

    func loadActiveArchive() {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<ArchiveRecord> = ArchiveRecord.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.fetchLimit = 1

        if let active = try? context.fetch(request).first {
            activeArchiveId = active.id
        } else {
            activeArchiveId = nil
        }
    }

    func setActiveArchive(_ archiveId: UUID?) {
        let context = persistentContainer.viewContext

        let allRequest: NSFetchRequest<ArchiveRecord> = ArchiveRecord.fetchRequest()
        allRequest.predicate = NSPredicate(format: "isActive == YES")
        if let activeRecords = try? context.fetch(allRequest) {
            activeRecords.forEach { $0.isActive = false }
        }

        if let archiveId {
            let request: NSFetchRequest<ArchiveRecord> = ArchiveRecord.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", archiveId as CVarArg)
            request.fetchLimit = 1
            if let record = try? context.fetch(request).first {
                record.isActive = true
            }
        }

        saveContext()
        activeArchiveId = archiveId
        NotificationCenter.default.post(name: .archiveChanged, object: nil)
    }
}
