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

    var icon: String {
        switch self {
        case .active: return "checkmark.circle"
        case .withdrawn: return "xmark.circle"
        case .stored: return "archivebox"
        case .damaged: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Set Definition (hardcoded metadata)

struct SetDefinition {
    let code: String
    let name: String
    let listOrder: Int
    let yearIntroduced: Int
    let carsPerSet: Int
    let defaultBuilder: String
    let wikiArticle: String
    let networkLine: String // e.g. "Sydney Trains" or "NSW TrainLink"

    static let all: [SetDefinition] = [
        .init(code: "D", name: "Mariyung",   listOrder: 0,  yearIntroduced: 2023, carsPerSet: 8,  defaultBuilder: "Hyundai Rotem",              wikiArticle: "Sydney_Trains_D_set", networkLine: "Sydney Trains"),
        .init(code: "B", name: "Waratah 2",  listOrder: 1,  yearIntroduced: 2018, carsPerSet: 8,  defaultBuilder: "Downer/CRRC Changchun",      wikiArticle: "Sydney_Trains_B_set", networkLine: "Sydney Trains"),
        .init(code: "A", name: "Waratah",    listOrder: 2,  yearIntroduced: 2011, carsPerSet: 8,  defaultBuilder: "Downer EDI/CNR Changchun",   wikiArticle: "Sydney_Trains_A_set", networkLine: "Sydney Trains"),
        .init(code: "M", name: "Millennium",  listOrder: 3,  yearIntroduced: 2002, carsPerSet: 8,  defaultBuilder: "EDI/ABB",                    wikiArticle: "Sydney_Trains_M_set", networkLine: "Sydney Trains"),
        .init(code: "T", name: "Tangara",     listOrder: 4,  yearIntroduced: 1988, carsPerSet: 4,  defaultBuilder: "A. Goninan & Co.",           wikiArticle: "Sydney_Trains_T_set", networkLine: "Sydney Trains"),
        .init(code: "H", name: "OSCAR",       listOrder: 5,  yearIntroduced: 2006, carsPerSet: 4,  defaultBuilder: "UGL Rail",                   wikiArticle: "Sydney_Trains_H_set", networkLine: "Sydney Trains"),
        .init(code: "V", name: "V Set",       listOrder: 6,  yearIntroduced: 1970, carsPerSet: 8,  defaultBuilder: "Comeng/ABB",                 wikiArticle: "Sydney_Trains_V_set", networkLine: "NSW TrainLink"),
        .init(code: "K", name: "K Set",       listOrder: 7,  yearIntroduced: 1981, carsPerSet: 4,  defaultBuilder: "A. Goninan & Co.",           wikiArticle: "Sydney_Trains_K_set", networkLine: "Sydney Trains"),
        .init(code: "C", name: "C Set",       listOrder: 8,  yearIntroduced: 1972, carsPerSet: 4,  defaultBuilder: "Comeng",                     wikiArticle: "Sydney_Trains_C_set", networkLine: "Sydney Trains"),
        .init(code: "N", name: "Endeavour",   listOrder: 9,  yearIntroduced: 1994, carsPerSet: 2,  defaultBuilder: "A. Goninan & Co.",           wikiArticle: "NSW_TrainLink_Endeavour_railcar", networkLine: "NSW TrainLink"),
        .init(code: "J", name: "Hunter",      listOrder: 10, yearIntroduced: 2006, carsPerSet: 2,  defaultBuilder: "UGL Rail/ABB",               wikiArticle: "NSW_TrainLink_Hunter_railcar", networkLine: "NSW TrainLink"),
    ]
}

// MARK: - Fleet

struct Fleet {
    let sets: [FleetSet]

    static let empty = Fleet(sets: [])

    var totalTrains: Int { sets.reduce(0) { $0 + $1.totalTrains } }
    var totalCarriages: Int { sets.reduce(0) { $0 + $1.totalCarriages } }
    var activeTrains: Int { sets.reduce(0) { $0 + $1.activeTrains } }
    var retiredTrains: Int { sets.reduce(0) { $0 + $1.retiredTrains } }

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
                networkLine: def.networkLine,
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
    let networkLine: String
    let trains: [FleetTrain]

    var totalCarriages: Int { trains.reduce(0) { $0 + $1.carriages.count } }
    var totalTrains: Int { trains.count }
    var activeTrains: Int { trains.filter { !$0.isRetired }.count }
    var retiredTrains: Int { trains.filter { $0.isRetired }.count }
    var uniqueDepots: [String] { Array(Set(trains.map(\.depot).filter { !$0.isEmpty })).sorted() }
    var uniqueBuilders: [String] { Array(Set(trains.map(\.builder).filter { !$0.isEmpty })).sorted() }
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
    // Core counts
    let totalTrips: Int
    let tripsToday: Int
    let tripsThisWeek: Int
    let tripsThisMonth: Int
    let setsRidden: Int
    let totalSets: Int
    let trainsRidden: Int
    let carriagesRidden: Int

    // Favourites
    let mostRiddenSetName: String
    let mostRiddenSetTrips: Int
    let mostRiddenTrainName: String
    let mostRiddenTrainTrips: Int
    let mostRiddenCarriage: String
    let mostRiddenCarriageTrips: Int

    // Time stats
    let firstTripDate: Date?
    let latestTripDate: Date?
    let longestStreak: Int
    let currentStreak: Int
    let uniqueDays: Int
    let avgTripsPerActiveDay: Double

    // Distribution
    let tripsByDayOfWeek: [Int]  // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
    let tripsByHour: [Int]       // 24 elements
    let peakHourLabel: String
    let busiestDayLabel: String

    // Locations
    let uniqueLocations: Int
    let topLocationName: String
    let topLocationTrips: Int

    // Per-entity breakdowns
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
        let firstRiddenDate: Date?
    }

    struct TrainStats {
        let tripCount: Int
        let carriagesRidden: Int
        let totalCarriages: Int
        let lastRiddenDate: Date?
        let firstRiddenDate: Date?
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
        totalTrips: 0, tripsToday: 0, tripsThisWeek: 0, tripsThisMonth: 0,
        setsRidden: 0, totalSets: 0, trainsRidden: 0, carriagesRidden: 0,
        mostRiddenSetName: "-", mostRiddenSetTrips: 0,
        mostRiddenTrainName: "-", mostRiddenTrainTrips: 0,
        mostRiddenCarriage: "-", mostRiddenCarriageTrips: 0,
        firstTripDate: nil, latestTripDate: nil,
        longestStreak: 0, currentStreak: 0, uniqueDays: 0, avgTripsPerActiveDay: 0,
        tripsByDayOfWeek: Array(repeating: 0, count: 7),
        tripsByHour: Array(repeating: 0, count: 24),
        peakHourLabel: "-", busiestDayLabel: "-",
        uniqueLocations: 0, topLocationName: "-", topLocationTrips: 0,
        setStats: [:], trainStats: [:], carriageTripCounts: [:],
        recentTrips: []
    )

    static func compute(fleet: Fleet, trips: [StoredTrip]) -> FleetStats {
        let now = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!

        let totalTrips = trips.count
        let tripsToday = trips.filter { ($0.date ?? .distantPast) >= todayStart }.count
        let tripsThisWeek = trips.filter { ($0.date ?? .distantPast) >= weekAgo }.count
        let tripsThisMonth = trips.filter { ($0.date ?? .distantPast) >= monthAgo }.count

        // Group trips by carriage code
        var carriageTripCounts = [String: Int]()
        var carriageFirstDate = [String: Date]()
        var carriageLastDate = [String: Date]()
        for trip in trips {
            guard let code = trip.carriageCode else { continue }
            carriageTripCounts[code, default: 0] += 1
            let date = trip.date ?? .distantPast
            if carriageFirstDate[code] == nil || date < carriageFirstDate[code]! {
                carriageFirstDate[code] = date
            }
            if carriageLastDate[code] == nil || date > carriageLastDate[code]! {
                carriageLastDate[code] = date
            }
        }

        // Build lookup: carriage code → (setCode, setName, trainName)
        var lookup = [String: (setCode: String, setName: String, trainName: String)]()
        for set in fleet.sets {
            for train in set.trains {
                for code in train.carriages {
                    lookup[code] = (set.code, set.name, train.name)
                }
            }
        }

        // Time distributions
        var dayOfWeek = Array(repeating: 0, count: 7)
        var hourOfDay = Array(repeating: 0, count: 24)
        var allDays = Set<String>()
        var locationCounts = [String: Int]()
        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "yyyy-MM-dd"
        var firstDate: Date?
        var latestDate: Date?

        for trip in trips {
            guard let date = trip.date else { continue }
            let dow = (calendar.component(.weekday, from: date) + 5) % 7 // Mon=0
            dayOfWeek[dow] += 1
            hourOfDay[calendar.component(.hour, from: date)] += 1
            allDays.insert(dayFmt.string(from: date))
            if firstDate == nil || date < firstDate! { firstDate = date }
            if latestDate == nil || date > latestDate! { latestDate = date }
            if let loc = trip.locationName, !loc.isEmpty {
                locationCounts[loc, default: 0] += 1
            }
        }

        let peakHour = hourOfDay.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        let peakHourLabel = totalTrips > 0 ? formatHour(peakHour) : "-"

        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let busiestDayIdx = dayOfWeek.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        let busiestDayLabel = totalTrips > 0 ? dayNames[busiestDayIdx] : "-"

        let uniqueDays = allDays.count
        let avgPerDay = uniqueDays > 0 ? Double(totalTrips) / Double(uniqueDays) : 0

        // Streaks
        let sortedDays = allDays.sorted().reversed().compactMap { dayFmt.date(from: $0) }.map { calendar.startOfDay(for: $0) }
        let (currentStreak, longestStreak) = computeStreaks(sortedDays: Array(Set(sortedDays)).sorted(by: >), calendar: calendar)

        // Locations
        let topLocation = locationCounts.max(by: { $0.value < $1.value })
        let uniqueLocations = locationCounts.count

        // Most ridden carriage
        let topCarriage = carriageTripCounts.max(by: { $0.value < $1.value })

        // Per-train and per-set stats
        var trainStatsMap = [String: TrainStats]()
        var setStatsMap = [String: SetStats]()
        var setsRidden = 0
        var totalTrainsRidden = 0
        var totalCarriagesRidden = 0
        var maxSetTrips = 0
        var maxSetName = "-"
        var maxTrainTrips = 0
        var maxTrainName = "-"

        for set in fleet.sets {
            var setTrips = 0
            var setTrainsRidden = 0
            var setCarriagesRidden = 0
            var setLastDate: Date?
            var setFirstDate: Date?

            for train in set.trains {
                var trainTrips = 0
                var trainCarriagesRidden = 0
                var trainLastDate: Date?
                var trainFirstDate: Date?

                for code in train.carriages {
                    let count = carriageTripCounts[code] ?? 0
                    trainTrips += count
                    if count > 0 {
                        trainCarriagesRidden += 1
                        if let d = carriageLastDate[code] {
                            if trainLastDate == nil || d > trainLastDate! { trainLastDate = d }
                        }
                        if let d = carriageFirstDate[code] {
                            if trainFirstDate == nil || d < trainFirstDate! { trainFirstDate = d }
                        }
                    }
                }

                trainStatsMap[train.name] = TrainStats(
                    tripCount: trainTrips,
                    carriagesRidden: trainCarriagesRidden,
                    totalCarriages: train.carriages.count,
                    lastRiddenDate: trainLastDate,
                    firstRiddenDate: trainFirstDate
                )

                setTrips += trainTrips
                setCarriagesRidden += trainCarriagesRidden
                if trainTrips > 0 {
                    setTrainsRidden += 1
                    totalTrainsRidden += 1
                }
                totalCarriagesRidden += trainCarriagesRidden
                if let d = trainLastDate, setLastDate == nil || d > setLastDate! { setLastDate = d }
                if let d = trainFirstDate, setFirstDate == nil || d < setFirstDate! { setFirstDate = d }

                if trainTrips > maxTrainTrips {
                    maxTrainTrips = trainTrips
                    maxTrainName = train.name
                }
            }

            setStatsMap[set.code] = SetStats(
                tripCount: setTrips,
                trainsRidden: setTrainsRidden,
                totalTrains: set.totalTrains,
                carriagesRidden: setCarriagesRidden,
                totalCarriages: set.totalCarriages,
                lastRiddenDate: setLastDate,
                firstRiddenDate: setFirstDate
            )

            if setTrips > 0 { setsRidden += 1 }
            if setTrips > maxSetTrips {
                maxSetTrips = setTrips
                maxSetName = set.name
            }
        }

        // Recent trips (last 10)
        let recentTrips: [RecentTrip] = trips.prefix(10).compactMap { trip in
            guard let code = trip.carriageCode, let date = trip.date else { return nil }
            let info = lookup[code]
            return RecentTrip(
                id: UUID(),
                carriageCode: code,
                trainName: info?.trainName ?? "Unknown",
                setName: info?.setName ?? "Unknown",
                date: date,
                locationName: trip.locationName ?? ""
            )
        }

        return FleetStats(
            totalTrips: totalTrips,
            tripsToday: tripsToday,
            tripsThisWeek: tripsThisWeek,
            tripsThisMonth: tripsThisMonth,
            setsRidden: setsRidden,
            totalSets: fleet.sets.count,
            trainsRidden: totalTrainsRidden,
            carriagesRidden: totalCarriagesRidden,
            mostRiddenSetName: maxSetName,
            mostRiddenSetTrips: maxSetTrips,
            mostRiddenTrainName: maxTrainName,
            mostRiddenTrainTrips: maxTrainTrips,
            mostRiddenCarriage: topCarriage?.key ?? "-",
            mostRiddenCarriageTrips: topCarriage?.value ?? 0,
            firstTripDate: firstDate,
            latestTripDate: latestDate,
            longestStreak: longestStreak,
            currentStreak: currentStreak,
            uniqueDays: uniqueDays,
            avgTripsPerActiveDay: avgPerDay,
            tripsByDayOfWeek: dayOfWeek,
            tripsByHour: hourOfDay,
            peakHourLabel: peakHourLabel,
            busiestDayLabel: busiestDayLabel,
            uniqueLocations: uniqueLocations,
            topLocationName: topLocation?.key ?? "-",
            topLocationTrips: topLocation?.value ?? 0,
            setStats: setStatsMap,
            trainStats: trainStatsMap,
            carriageTripCounts: carriageTripCounts,
            recentTrips: recentTrips
        )
    }

    private static func computeStreaks(sortedDays: [Date], calendar: Calendar) -> (current: Int, longest: Int) {
        guard !sortedDays.isEmpty else { return (0, 0) }

        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 1

        // Current streak (from today backwards)
        let today = calendar.startOfDay(for: Date())
        if let first = sortedDays.first, first == today || first == calendar.date(byAdding: .day, value: -1, to: today) {
            currentStreak = 1
            var check = first
            for day in sortedDays.dropFirst() {
                let expected = calendar.date(byAdding: .day, value: -1, to: check)!
                if day == expected {
                    currentStreak += 1
                    check = day
                } else {
                    break
                }
            }
        }

        // Longest streak
        let ascending = sortedDays.reversed()
        var prev: Date?
        for day in ascending {
            if let p = prev {
                let expected = calendar.date(byAdding: .day, value: 1, to: p)!
                if day == expected {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            }
            prev = day
        }
        longestStreak = max(longestStreak, tempStreak)

        return (currentStreak, longestStreak)
    }

    private static func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var comps = DateComponents()
        comps.hour = hour
        if let date = Calendar.current.date(from: comps) {
            return formatter.string(from: date).lowercased()
        }
        return "\(hour):00"
    }
}
