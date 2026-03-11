//
//  Fleet.swift
//  TrainTrack
//

import Foundation
import CoreData

// MARK: - Train Status

enum TrainStatus: String, Codable, CaseIterable {
    case active, withdrawn, stored, damaged

    var displayName: String { rawValue.capitalized }
}

// MARK: - Set Definition (hardcoded metadata)

struct SetDefinition {
    let code: String
    let name: String
    let listOrder: Int
    let yearIntroduced: Int
    let carsPerSet: Int
    let defaultBuilder: String
    /// Wikipedia article title for image fetching
    let wikiArticle: String

    static let all: [SetDefinition] = [
        .init(code: "D", name: "Mariyung",   listOrder: 0,  yearIntroduced: 2023, carsPerSet: 8,  defaultBuilder: "Hyundai Rotem",              wikiArticle: "Sydney_Trains_D_set"),
        .init(code: "B", name: "Waratah 2",  listOrder: 1,  yearIntroduced: 2018, carsPerSet: 8,  defaultBuilder: "Downer/CRRC Changchun",      wikiArticle: "Sydney_Trains_B_set"),
        .init(code: "A", name: "Waratah",    listOrder: 2,  yearIntroduced: 2011, carsPerSet: 8,  defaultBuilder: "Downer EDI/CNR Changchun",   wikiArticle: "Sydney_Trains_A_set"),
        .init(code: "M", name: "Millennium",  listOrder: 3,  yearIntroduced: 2002, carsPerSet: 8,  defaultBuilder: "EDI/ABB",                    wikiArticle: "Sydney_Trains_M_set"),
        .init(code: "T", name: "Tangara",     listOrder: 4,  yearIntroduced: 1988, carsPerSet: 4,  defaultBuilder: "A. Goninan & Co.",           wikiArticle: "Sydney_Trains_T_set"),
        .init(code: "H", name: "OSCAR",       listOrder: 5,  yearIntroduced: 2006, carsPerSet: 4,  defaultBuilder: "UGL Rail",                   wikiArticle: "Sydney_Trains_H_set"),
        .init(code: "V", name: "V Set",       listOrder: 6,  yearIntroduced: 1970, carsPerSet: 8,  defaultBuilder: "Comeng/ABB",                 wikiArticle: "Sydney_Trains_V_set"),
        .init(code: "K", name: "K Set",       listOrder: 7,  yearIntroduced: 1981, carsPerSet: 4,  defaultBuilder: "A. Goninan & Co.",           wikiArticle: "Sydney_Trains_K_set"),
        .init(code: "C", name: "C Set",       listOrder: 8,  yearIntroduced: 1972, carsPerSet: 4,  defaultBuilder: "Comeng",                     wikiArticle: "Sydney_Trains_C_set"),
        .init(code: "N", name: "Endeavour",   listOrder: 9,  yearIntroduced: 1994, carsPerSet: 2,  defaultBuilder: "A. Goninan & Co.",           wikiArticle: "NSW_TrainLink_Endeavour_railcar"),
        .init(code: "J", name: "Hunter",      listOrder: 10, yearIntroduced: 2006, carsPerSet: 2,  defaultBuilder: "UGL Rail/ABB",               wikiArticle: "NSW_TrainLink_Hunter_railcar"),
    ]
}

// MARK: - Fleet

struct Fleet {
    let sets: [FleetSet]

    static let empty = Fleet(sets: [])

    /// Builds a Fleet from parsed wiki train data + hardcoded set definitions.
    static func build(from parsedTrains: [ParsedTrain]) -> Fleet {
        var trainsBySet = [String: [FleetTrain]]()

        for parsed in parsedTrains {
            guard let initial = parsed.setCode.first else { continue }
            let key = String(initial).uppercased()

            let train = FleetTrain(
                name: parsed.setCode,
                carriages: parsed.carriages,
                builder: parsed.builder ?? "",
                depot: parsed.depot ?? "",
                notes: parsed.notes ?? "",
                status: parsed.status
            )

            trainsBySet[key, default: []].append(train)
        }

        let sets = SetDefinition.all.map { def in
            let trains = (trainsBySet[def.code] ?? [])
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

            return FleetSet(
                code: def.code,
                name: def.name,
                yearIntroduced: def.yearIntroduced,
                carsPerSet: def.carsPerSet,
                defaultBuilder: def.defaultBuilder,
                listOrder: def.listOrder,
                trains: trains
            )
        }

        return Fleet(sets: sets)
    }
}

// MARK: - Fleet Set

struct FleetSet: Identifiable, Hashable {
    var id: String { code }
    let code: String
    let name: String
    let yearIntroduced: Int
    let carsPerSet: Int
    let defaultBuilder: String
    let listOrder: Int
    let trains: [FleetTrain]

    var totalCarriages: Int { trains.reduce(0) { $0 + $1.carriages.count } }
    var totalTrains: Int { trains.count }
}

// MARK: - Fleet Train

struct FleetTrain: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let carriages: [String]
    let builder: String
    let depot: String
    let notes: String
    let status: TrainStatus

    var isRetired: Bool { status != .active }
}

// MARK: - Fleet Stats

struct FleetStats {
    let totalTrips: Int
    let tripsThisWeek: Int
    let tripsThisMonth: Int
    let setsRidden: Int
    let totalSets: Int
    let trainsRidden: Int
    let carriagesRidden: Int
    let mostRiddenSetName: String
    let mostRiddenSetTrips: Int

    let setStats: [String: SetStats]
    let trainStats: [String: TrainStats]
    let carriageTripCounts: [String: Int]

    let recentTrips: [RecentTrip]

    struct SetStats {
        let tripCount: Int
        let trainsRidden: Int
        let totalTrains: Int
        let carriagesRidden: Int
        let totalCarriages: Int
        let lastRiddenDate: Date?
    }

    struct TrainStats {
        let tripCount: Int
        let carriagesRidden: Int
        let totalCarriages: Int
        let lastRiddenDate: Date?
    }

    struct RecentTrip: Identifiable {
        let id: UUID
        let carriageCode: String
        let trainName: String
        let setName: String
        let date: Date
        let locationName: String
    }

    static let empty = FleetStats(
        totalTrips: 0, tripsThisWeek: 0, tripsThisMonth: 0,
        setsRidden: 0, totalSets: 0, trainsRidden: 0, carriagesRidden: 0,
        mostRiddenSetName: "-", mostRiddenSetTrips: 0,
        setStats: [:], trainStats: [:], carriageTripCounts: [:],
        recentTrips: []
    )

    static func compute(fleet: Fleet, trips: [StoredTrip]) -> FleetStats {
        let now = Date()
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!

        let totalTrips = trips.count
        let tripsThisWeek = trips.filter { ($0.date ?? .distantPast) >= weekAgo }.count
        let tripsThisMonth = trips.filter { ($0.date ?? .distantPast) >= monthAgo }.count

        // Group trips by carriage code
        var carriageTripCounts = [String: Int]()
        var carriageLastDate = [String: Date]()
        for trip in trips {
            guard let code = trip.carriageCode else { continue }
            carriageTripCounts[code, default: 0] += 1
            let date = trip.date ?? .distantPast
            if carriageLastDate[code] == nil || date > carriageLastDate[code]! {
                carriageLastDate[code] = date
            }
        }

        // Build temporary lookup: carriage code → (setCode, setName, trainName)
        var lookup = [String: (setCode: String, setName: String, trainName: String)]()
        for set in fleet.sets {
            for train in set.trains {
                for code in train.carriages {
                    lookup[code] = (set.code, set.name, train.name)
                }
            }
        }

        // Per-train and per-set stats
        var trainStatsMap = [String: TrainStats]()
        var setStatsMap = [String: SetStats]()
        var setsRidden = 0
        var totalTrainsRidden = 0
        var totalCarriagesRidden = 0
        var maxSetTrips = 0
        var maxSetName = "-"

        for set in fleet.sets {
            var setTrips = 0
            var setTrainsRidden = 0
            var setCarriagesRidden = 0
            var setLastDate: Date?

            for train in set.trains {
                var trainTrips = 0
                var trainCarriagesRidden = 0
                var trainLastDate: Date?

                for code in train.carriages {
                    let count = carriageTripCounts[code] ?? 0
                    trainTrips += count
                    if count > 0 {
                        trainCarriagesRidden += 1
                        if let date = carriageLastDate[code],
                           trainLastDate == nil || date > trainLastDate! {
                            trainLastDate = date
                        }
                    }
                }

                trainStatsMap[train.name] = TrainStats(
                    tripCount: trainTrips,
                    carriagesRidden: trainCarriagesRidden,
                    totalCarriages: train.carriages.count,
                    lastRiddenDate: trainLastDate
                )

                setTrips += trainTrips
                setCarriagesRidden += trainCarriagesRidden
                if trainTrips > 0 {
                    setTrainsRidden += 1
                    totalTrainsRidden += 1
                }
                totalCarriagesRidden += trainCarriagesRidden
                if let d = trainLastDate, setLastDate == nil || d > setLastDate! {
                    setLastDate = d
                }
            }

            setStatsMap[set.code] = SetStats(
                tripCount: setTrips,
                trainsRidden: setTrainsRidden,
                totalTrains: set.totalTrains,
                carriagesRidden: setCarriagesRidden,
                totalCarriages: set.totalCarriages,
                lastRiddenDate: setLastDate
            )

            if setTrips > 0 { setsRidden += 1 }
            if setTrips > maxSetTrips {
                maxSetTrips = setTrips
                maxSetName = set.name
            }
        }

        // Recent trips (last 5)
        let recentTrips: [RecentTrip] = trips.prefix(5).compactMap { trip in
            guard let code = trip.carriageCode, let date = trip.date else { return nil }
            let info = lookup[code]
            return RecentTrip(
                id: UUID(),
                carriageCode: code,
                trainName: info?.trainName ?? "Unknown",
                setName: info?.setName ?? "Unknown",
                date: date,
                locationName: trip.locationName ?? "Unknown"
            )
        }

        return FleetStats(
            totalTrips: totalTrips,
            tripsThisWeek: tripsThisWeek,
            tripsThisMonth: tripsThisMonth,
            setsRidden: setsRidden,
            totalSets: fleet.sets.count,
            trainsRidden: totalTrainsRidden,
            carriagesRidden: totalCarriagesRidden,
            mostRiddenSetName: maxSetName,
            mostRiddenSetTrips: maxSetTrips,
            setStats: setStatsMap,
            trainStats: trainStatsMap,
            carriageTripCounts: carriageTripCounts,
            recentTrips: recentTrips
        )
    }
}
