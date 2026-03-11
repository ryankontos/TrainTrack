//
//  AchievementManager.swift
//  TrainTrack
//

import Foundation
import CoreData
import UserNotifications
import os.log

private let logger = Logger(subsystem: "com.ryankontos.traintrack", category: "Achievements")

final class AchievementManager {
    static let shared = AchievementManager()

    private static let storageKey = "UnlockedAchievements"

    // MARK: - Storage (JSON file in App Support)

    private static var storageURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("achievements.json")
    }

    private(set) var unlocked: [String: Date] = [:] // achievement id → unlock date

    private init() {
        loadFromDisk()
    }

    // MARK: - Achievement Definitions

    struct Achievement: Identifiable {
        let id: String
        let title: String
        let description: String
        let category: Category
        let icon: String
        let target: Int

        enum Category: String, CaseIterable {
            case milestones = "Milestones"
            case exploration = "Exploration"
            case completion = "Completion"
            case dedication = "Dedication"
            case special = "Special"

            var color: String {
                switch self {
                case .milestones: return "blue"
                case .exploration: return "green"
                case .completion: return "purple"
                case .dedication: return "orange"
                case .special: return "red"
                }
            }
        }
    }

    static let all: [Achievement] = [
        // Milestones
        .init(id: "first-trip",   title: "First Trip",     description: "Log your first trip.",               category: .milestones, icon: "star",         target: 1),
        .init(id: "trips-10",     title: "Regular",        description: "Log 10 trips.",                      category: .milestones, icon: "star.fill",    target: 10),
        .init(id: "trips-50",     title: "Commuter",       description: "Log 50 trips.",                      category: .milestones, icon: "star.circle",  target: 50),
        .init(id: "trips-100",    title: "Centurion",      description: "Log 100 trips.",                     category: .milestones, icon: "trophy",       target: 100),
        .init(id: "trips-500",    title: "Veteran",        description: "Log 500 trips.",                     category: .milestones, icon: "trophy.fill",  target: 500),
        .init(id: "trips-1000",   title: "Legend",         description: "Log 1,000 trips.",                   category: .milestones, icon: "crown",        target: 1000),

        // Exploration
        .init(id: "sets-3",       title: "Explorer",       description: "Ride 3 different fleet types.",       category: .exploration, icon: "map",         target: 3),
        .init(id: "sets-all",     title: "Fleet Master",   description: "Ride every fleet type.",              category: .exploration, icon: "map.fill",    target: 11),
        .init(id: "trains-10",    title: "Train Hopper",   description: "Ride 10 different trains.",           category: .exploration, icon: "tram",        target: 10),
        .init(id: "trains-50",    title: "Spotter",        description: "Ride 50 different trains.",           category: .exploration, icon: "tram.fill",   target: 50),
        .init(id: "trains-100",   title: "Collector",      description: "Ride 100 different trains.",          category: .exploration, icon: "binoculars",  target: 100),
        .init(id: "depots-3",     title: "Depot Visitor",  description: "Ride trains from 3 different depots.",category: .exploration, icon: "building.2",  target: 3),

        // Completion
        .init(id: "complete-set", title: "Set Complete",   description: "Ride every train in a fleet type.",   category: .completion, icon: "checkmark.seal",     target: 1),
        .init(id: "complete-2",   title: "Double Complete", description: "Complete 2 fleet types.",            category: .completion, icon: "checkmark.seal.fill", target: 2),
        .init(id: "complete-all", title: "Completionist",  description: "Complete every fleet type.",          category: .completion, icon: "rosette",            target: 11),

        // Dedication
        .init(id: "streak-7",    title: "Week Streak",    description: "Log trips 7 days in a row.",          category: .dedication, icon: "flame",        target: 7),
        .init(id: "streak-30",   title: "Month Streak",   description: "Log trips 30 days in a row.",         category: .dedication, icon: "flame.fill",   target: 30),
        .init(id: "early-bird",  title: "Early Bird",     description: "Log a trip before 6 AM.",             category: .dedication, icon: "sunrise",      target: 1),
        .init(id: "night-owl",   title: "Night Owl",      description: "Log a trip after 11 PM.",             category: .dedication, icon: "moon.stars",   target: 1),
        .init(id: "days-unique-30", title: "Monthly Rider", description: "Log trips on 30 different days.",   category: .dedication, icon: "calendar",     target: 30),

        // Special
        .init(id: "ride-retired", title: "History Buff",   description: "Log a trip on a retired train.",      category: .special, icon: "clock.arrow.circlepath", target: 1),
        .init(id: "locations-5",  title: "Traveller",      description: "Log trips from 5 different locations.",category: .special, icon: "location",             target: 5),
        .init(id: "all-carriages-train", title: "Full House", description: "Ride every carriage on a single train.", category: .special, icon: "train.side.front.car", target: 1),
    ]

    // MARK: - Evaluation

    @discardableResult
    func evaluateAll(fleet: Fleet, stats: FleetStats) -> [Achievement] {
        var newlyUnlocked = [Achievement]()

        for achievement in Self.all {
            guard unlocked[achievement.id] == nil else { continue }
            let current = currentValue(for: achievement, fleet: fleet, stats: stats)
            if current >= achievement.target {
                unlocked[achievement.id] = Date()
                newlyUnlocked.append(achievement)
            }
        }

        if !newlyUnlocked.isEmpty {
            saveToDisk()
            for a in newlyUnlocked {
                logger.info("Achievement unlocked: \(a.title)")
                sendNotification(for: a)
            }
        }

        return newlyUnlocked
    }

    func currentValue(for achievement: Achievement, fleet: Fleet, stats: FleetStats) -> Int {
        switch achievement.id {
        case "first-trip", "trips-10", "trips-50", "trips-100", "trips-500", "trips-1000":
            return stats.totalTrips
        case "sets-3", "sets-all":
            return stats.setsRidden
        case "trains-10", "trains-50", "trains-100":
            return stats.trainsRidden
        case "depots-3":
            return countUniqueDepots(fleet: fleet, stats: stats)
        case "complete-set", "complete-2", "complete-all":
            return countCompleteSets(fleet: fleet, stats: stats)
        case "streak-7", "streak-30":
            return currentStreak(stats: stats)
        case "early-bird":
            return hasEarlyTrip(stats: stats) ? 1 : 0
        case "night-owl":
            return hasLateTrip(stats: stats) ? 1 : 0
        case "days-unique-30":
            return countUniqueDays(stats: stats)
        case "ride-retired":
            return hasRetiredTrip(fleet: fleet, stats: stats) ? 1 : 0
        case "locations-5":
            return countUniqueLocations(stats: stats)
        case "all-carriages-train":
            return hasFullTrain(fleet: fleet, stats: stats) ? 1 : 0
        default:
            return 0
        }
    }

    func isUnlocked(_ id: String) -> Bool { unlocked[id] != nil }
    func unlockDate(_ id: String) -> Date? { unlocked[id] }

    // MARK: - Stat Helpers

    private func countUniqueDepots(fleet: Fleet, stats: FleetStats) -> Int {
        var depots = Set<String>()
        for set in fleet.sets {
            for train in set.trains where (stats.trainStats[train.name]?.tripCount ?? 0) > 0 {
                if !train.depot.isEmpty { depots.insert(train.depot) }
            }
        }
        return depots.count
    }

    private func countCompleteSets(fleet: Fleet, stats: FleetStats) -> Int {
        fleet.sets.filter { set in
            guard !set.trains.isEmpty else { return false }
            let activeTrains = set.trains.filter { !$0.isRetired }
            guard !activeTrains.isEmpty else { return false }
            return activeTrains.allSatisfy { (stats.trainStats[$0.name]?.tripCount ?? 0) > 0 }
        }.count
    }

    private func currentStreak(stats: FleetStats) -> Int {
        let context = TTCloudKit.shared.persistentContainer.viewContext
        let request: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredTrip.date, ascending: false)]
        request.propertiesToFetch = ["date"]
        guard let trips = try? context.fetch(request) else { return 0 }

        let calendar = Calendar.current
        var days = Set<DateComponents>()
        for trip in trips {
            guard let date = trip.date else { continue }
            days.insert(calendar.dateComponents([.year, .month, .day], from: date))
        }

        var streak = 0
        var checkDate = Date()
        while true {
            let comps = calendar.dateComponents([.year, .month, .day], from: checkDate)
            if days.contains(comps) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    private func hasEarlyTrip(stats: FleetStats) -> Bool {
        let context = TTCloudKit.shared.persistentContainer.viewContext
        let request: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        guard let trips = try? context.fetch(request) else { return false }
        return trips.contains { trip in
            guard let date = trip.date else { return false }
            return Calendar.current.component(.hour, from: date) < 6
        }
    }

    private func hasLateTrip(stats: FleetStats) -> Bool {
        let context = TTCloudKit.shared.persistentContainer.viewContext
        let request: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        guard let trips = try? context.fetch(request) else { return false }
        return trips.contains { trip in
            guard let date = trip.date else { return false }
            return Calendar.current.component(.hour, from: date) >= 23
        }
    }

    private func countUniqueDays(stats: FleetStats) -> Int {
        let context = TTCloudKit.shared.persistentContainer.viewContext
        let request: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        guard let trips = try? context.fetch(request) else { return 0 }
        var days = Set<String>()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        for trip in trips {
            guard let date = trip.date else { continue }
            days.insert(fmt.string(from: date))
        }
        return days.count
    }

    private func hasRetiredTrip(fleet: Fleet, stats: FleetStats) -> Bool {
        for set in fleet.sets {
            for train in set.trains where train.isRetired {
                if (stats.trainStats[train.name]?.tripCount ?? 0) > 0 { return true }
            }
        }
        return false
    }

    private func countUniqueLocations(stats: FleetStats) -> Int {
        let context = TTCloudKit.shared.persistentContainer.viewContext
        let request: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        guard let trips = try? context.fetch(request) else { return 0 }
        var locations = Set<String>()
        for trip in trips {
            if let loc = trip.locationName, !loc.isEmpty { locations.insert(loc) }
        }
        return locations.count
    }

    private func hasFullTrain(fleet: Fleet, stats: FleetStats) -> Bool {
        for set in fleet.sets {
            for train in set.trains {
                guard !train.carriages.isEmpty else { continue }
                if train.carriages.allSatisfy({ (stats.carriageTripCounts[$0] ?? 0) > 0 }) {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: Self.storageURL),
              let dict = try? JSONDecoder().decode([String: Date].self, from: data) else { return }
        unlocked = dict
    }

    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(unlocked) else { return }
        try? data.write(to: Self.storageURL, options: .atomic)
    }

    // MARK: - Notifications

    private func sendNotification(for achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked!"
        content.body = "\(achievement.title) — \(achievement.description)"
        content.sound = .default

        let request = UNNotificationRequest(identifier: "achievement-\(achievement.id)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
