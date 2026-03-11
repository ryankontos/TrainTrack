//
//  FleetStore.swift
//  TrainTrack
//

import Foundation
import CoreData
import os.log

private let logger = Logger(subsystem: "com.ryankontos.traintrack", category: "FleetStore")

@MainActor
final class FleetStore: ObservableObject {
    static let shared = FleetStore()

    @Published private(set) var fleet = Fleet.empty
    @Published private(set) var stats = FleetStats.empty
    @Published private(set) var isLoading = true

    /// Fast O(1) lookup: carriage code → set + train + position
    private(set) var carriageIndex = [String: CarriageLookup]()

    struct CarriageLookup {
        let set: FleetSet
        let train: FleetTrain
        let position: Int
    }

    private let downloader = TrainDataDownloader()
    private var observers = [Any]()
    private var debounceTask: Task<Void, Never>?

    private init() {
        setupObservers()
    }

    // MARK: - Loading

    func load() {
        // 1. Instant load from disk cache
        if let cached = downloader.loadCachedTrains(), !cached.isEmpty {
            applyFleet(Fleet.build(from: cached))
            isLoading = false
            logger.info("Fleet loaded from cache: \(cached.count) trains")
        }

        // 2. Background wiki refresh
        Task {
            let fresh = await downloader.fetchFromWiki()
            if !fresh.isEmpty {
                applyFleet(Fleet.build(from: fresh))
                logger.info("Fleet refreshed from wiki: \(fresh.count) trains")
            }
            isLoading = false
        }
    }

    // MARK: - Stats

    func recomputeStats() {
        guard let cloudKit = TTCloudKit.shared else {
            logger.warning("TTCloudKit not initialized yet — skipping stats")
            return
        }
        let context = cloudKit.persistentContainer.viewContext
        let request: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredTrip.date, ascending: false)]

        let archiveId = cloudKit.activeArchiveId
        if let archiveId {
            request.predicate = NSPredicate(format: "archiveId == %@", archiveId as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "archiveId == nil")
        }

        let trips = (try? context.fetch(request)) ?? []
        stats = FleetStats.compute(fleet: fleet, trips: trips)
    }

    // MARK: - Lookups

    func findTrain(byCarriage code: String) -> CarriageLookup? {
        carriageIndex[code]
    }

    func searchCarriages(prefix: String) -> [CarriageLookup] {
        guard !prefix.isEmpty else { return [] }
        let upper = prefix.uppercased()
        return carriageIndex
            .filter { $0.key.uppercased().contains(upper) }
            .map { $0.value }
            .sorted { $0.train.name < $1.train.name }
    }

    /// All carriage codes in the fleet (for camera OCR matching).
    var allCarriageCodes: [String] {
        Array(carriageIndex.keys)
    }

    // MARK: - Private

    private func applyFleet(_ fleet: Fleet) {
        self.fleet = fleet
        buildIndex()
        recomputeStats()
    }

    private func buildIndex() {
        var index = [String: CarriageLookup]()
        for set in fleet.sets {
            for train in set.trains {
                for (i, code) in train.carriages.enumerated() {
                    index[code] = CarriageLookup(set: set, train: train, position: i)
                }
            }
        }
        carriageIndex = index
    }

    /// Debounced stats recompute + achievement evaluation.
    /// Coalesces rapid-fire iCloud sync notifications into a single update.
    private func scheduleDebouncedRecompute() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            guard !Task.isCancelled, let self else { return }
            self.recomputeStats()
            AchievementManager.shared.evaluateAll(fleet: self.fleet, stats: self.stats)
        }
    }

    private func setupObservers() {
        guard let cloudKit = TTCloudKit.shared else {
            logger.warning("TTCloudKit not initialized — deferring observers")
            return
        }
        // Recompute stats when CloudKit changes (debounced for bulk iCloud sync)
        let cloudSave = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: cloudKit.persistentContainer.viewContext,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                guard let self, Self.hasStoredTripChanges(notification) else { return }
                self.scheduleDebouncedRecompute()
            }
        }
        observers.append(cloudSave)

        let tripAdded = NotificationCenter.default.addObserver(
            forName: .tripAdded, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.recomputeStats() }
        }
        observers.append(tripAdded)

        let archiveChanged = NotificationCenter.default.addObserver(
            forName: .archiveChanged, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.recomputeStats() }
        }
        observers.append(archiveChanged)
    }

    private nonisolated static func hasStoredTripChanges(_ notification: Notification) -> Bool {
        guard let userInfo = notification.userInfo else { return false }
        let keys = [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey]
        let changed = keys.compactMap { userInfo[$0] as? Set<NSManagedObject> }.flatMap { $0 }
        return changed.contains { $0.entity.name == "StoredTrip" }
    }
}
