//
//  DashboardView.swift
//  TrainTrack
//

import SwiftUI
import CoreData

struct DashboardView: View {

    @ObservedObject private var store = FleetStore.shared
    @ObservedObject private var imageStore = FleetImageStore.shared

    private var s: FleetStats { store.stats }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroSection
                    streakBar
                    quickStatsGrid
                    if s.totalTrips > 0 {
                        fleetCompletionCard
                        personalRecords
                        activityPatterns
                        funFacts
                        fleetOverview
                        recentActivity
                    }
                    achievementsPreview
                }
                .padding(.bottom, 80)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("TrainTrack")
            .refreshable { store.load() }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 6) {
            Text("\(s.totalTrips)")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(.blue)
                .contentTransition(.numericText())

            Text(s.totalTrips == 1 ? "Trip Logged" : "Trips Logged")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            if let recent = s.recentTrips.first {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Last: **\(recent.trainName)** · \(recent.date.userFriendlyRelativeString()) \(recent.date.formattedTime())")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.blue.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(.blue.opacity(0.12), lineWidth: 1)
                )
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Streak Bar

    private var streakBar: some View {
        HStack(spacing: 12) {
            StreakPill(icon: "flame.fill", value: "\(s.currentStreak)", label: "Streak", color: .orange)
            StreakPill(icon: "calendar", value: "\(s.tripsToday)", label: "Today", color: .blue)
            StreakPill(icon: "chart.line.uptrend.xyaxis", value: "\(s.tripsThisWeek)", label: "Week", color: .green)
            StreakPill(icon: "calendar.badge.clock", value: "\(s.tripsThisMonth)", label: "Month", color: .purple)
        }
        .padding(.horizontal)
    }

    // MARK: - Quick Stats Grid

    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            MiniStatCard(icon: "tram.fill", value: "\(s.setsRidden)/\(s.totalSets)", label: "Sets", color: .blue, progress: s.totalSets > 0 ? Double(s.setsRidden) / Double(s.totalSets) : 0)
            MiniStatCard(icon: "train.side.front.car", value: "\(s.trainsRidden)", label: "Trains", color: .green, progress: store.fleet.totalTrains > 0 ? Double(s.trainsRidden) / Double(store.fleet.totalTrains) : nil)
            MiniStatCard(icon: "train.side.middle.car", value: "\(s.carriagesRidden)", label: "Carriages", color: .cyan, progress: store.fleet.totalCarriages > 0 ? Double(s.carriagesRidden) / Double(store.fleet.totalCarriages) : nil)
        }
        .padding(.horizontal)
    }

    // MARK: - Fleet Completion

    @ViewBuilder
    private var fleetCompletionCard: some View {
        let totalTrains = store.fleet.totalTrains
        let totalCarriages = store.fleet.totalCarriages
        let trainPct = totalTrains > 0 ? Double(s.trainsRidden) / Double(totalTrains) : 0
        let carriagePct = totalCarriages > 0 ? Double(s.carriagesRidden) / Double(totalCarriages) : 0

        if totalTrains > 0 {
            VStack(alignment: .leading, spacing: 14) {
                Text("Fleet Completion")
                    .font(.headline)

                HStack(spacing: 20) {
                    CompletionRing(progress: trainPct, label: "Trains", detail: "\(s.trainsRidden)/\(totalTrains)", color: .green)
                    CompletionRing(progress: carriagePct, label: "Carriages", detail: "\(s.carriagesRidden)/\(totalCarriages)", color: .cyan)
                    CompletionRing(progress: s.totalSets > 0 ? Double(s.setsRidden) / Double(s.totalSets) : 0, label: "Sets", detail: "\(s.setsRidden)/\(s.totalSets)", color: .blue)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
        }
    }

    // MARK: - Personal Records

    private var personalRecords: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                RecordCard(icon: "trophy.fill", label: "Longest Streak", value: "\(s.longestStreak) days", color: .orange)
                RecordCard(icon: "number", label: "Active Days", value: "\(s.uniqueDays)", color: .purple)
                RecordCard(icon: "star.fill", label: "Top Train", value: s.mostRiddenTrainName != "-" ? "\(s.mostRiddenTrainName) (\(s.mostRiddenTrainTrips))" : "-", color: .yellow)
                RecordCard(icon: "mappin.and.ellipse", label: "Locations", value: "\(s.uniqueLocations)", color: .red)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Activity Patterns

    private var activityPatterns: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Activity Patterns")
                .font(.headline)

            // Day of week mini bar chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Trips by Day")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                DayOfWeekChart(data: s.tripsByDayOfWeek)
            }

            // Peak time & busiest day
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(s.peakHourLabel)
                        .font(.subheadline.bold())
                    Text("Peak Hour")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(s.busiestDayLabel)
                        .font(.subheadline.bold())
                    Text("Busiest Day")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Image(systemName: "chart.bar")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(String(format: "%.1f", s.avgTripsPerActiveDay))
                        .font(.subheadline.bold())
                    Text("Per Active Day")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Fun Facts

    @ViewBuilder
    private var funFacts: some View {
        let facts = buildFunFacts()
        if !facts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Insights")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(facts, id: \.title) { fact in
                            FunFactCard(icon: fact.icon, title: fact.title, detail: fact.detail, color: fact.color)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Fleet Overview

    @ViewBuilder
    private var fleetOverview: some View {
        if !store.fleet.sets.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Fleet Overview")
                        .font(.headline)
                    Spacer()
                    Text("\(store.fleet.activeTrains) active · \(store.fleet.retiredTrains) retired")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                ForEach(store.fleet.sets) { set in
                    SetOverviewRow(set: set, stats: s.setStats[set.code], imageStore: imageStore)
                }
            }
        }
    }

    // MARK: - Recent Activity

    @ViewBuilder
    private var recentActivity: some View {
        if !s.recentTrips.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(s.recentTrips.prefix(5)) { trip in
                    RecentTripCard(trip: trip)
                }
            }
        }
    }

    // MARK: - Achievements

    @ViewBuilder
    private var achievementsPreview: some View {
        let unlockedIds = AchievementManager.shared.unlocked
        let unlockedAchievements = AchievementManager.all.filter { unlockedIds[$0.id] != nil }
        let totalAchievements = AchievementManager.all.count

        // Find next achievement close to unlocking
        let nextUp = AchievementManager.all
            .filter { unlockedIds[$0.id] == nil }
            .compactMap { a -> (AchievementManager.Achievement, Double)? in
                let cur = AchievementManager.shared.currentValue(for: a, fleet: store.fleet, stats: s)
                let pct = a.target > 0 ? Double(cur) / Double(a.target) : 0
                return pct > 0 ? (a, pct) : nil
            }
            .sorted { $0.1 > $1.1 }
            .first

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    AchievementsView()
                } label: {
                    Text("\(unlockedAchievements.count)/\(totalAchievements)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal)

            if let (nextAchievement, progress) = nextUp {
                HStack(spacing: 12) {
                    Image(systemName: nextAchievement.icon)
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .frame(width: 36, height: 36)
                        .background(.orange.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next: \(nextAchievement.title)")
                            .font(.subheadline.bold())
                        ProgressView(value: progress)
                            .tint(.orange)
                    }

                    Text("\(Int(progress * 100))%")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal)
            }

            if unlockedAchievements.isEmpty {
                Text("Log trips to unlock achievements!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(unlockedAchievements.suffix(8), id: \.id) { a in
                            AchievementBadge(achievement: a, unlocked: true)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Fun Fact Builder

    private struct FunFact {
        let icon: String
        let title: String
        let detail: String
        let color: Color
    }

    private func buildFunFacts() -> [FunFact] {
        var facts = [FunFact]()

        if s.mostRiddenSetName != "-" {
            facts.append(FunFact(icon: "star.fill", title: "Favourite Set", detail: "\(s.mostRiddenSetName)\n\(s.mostRiddenSetTrips) trips", color: .yellow))
        }

        if s.mostRiddenTrainName != "-" {
            facts.append(FunFact(icon: "train.side.front.car", title: "Top Train", detail: "\(s.mostRiddenTrainName)\n\(s.mostRiddenTrainTrips) trips", color: .green))
        }

        if s.mostRiddenCarriage != "-" {
            facts.append(FunFact(icon: "train.side.middle.car", title: "Top Carriage", detail: "\(s.mostRiddenCarriage)\n\(s.mostRiddenCarriageTrips) trips", color: .cyan))
        }

        if s.uniqueDays > 0 {
            facts.append(FunFact(icon: "calendar.badge.clock", title: "Active Days", detail: "\(s.uniqueDays) days\n\(String(format: "%.1f", s.avgTripsPerActiveDay)) per day", color: .purple))
        }

        if s.topLocationName != "-" {
            facts.append(FunFact(icon: "location.fill", title: "Top Spot", detail: "\(s.topLocationName)\n\(s.topLocationTrips) trips", color: .red))
        }

        let retiredRidden = store.fleet.sets.flatMap(\.trains).filter(\.isRetired).filter { (s.trainStats[$0.name]?.tripCount ?? 0) > 0 }.count
        if retiredRidden > 0 {
            facts.append(FunFact(icon: "clock.arrow.circlepath", title: "Historic", detail: "\(retiredRidden) retired\ntrains ridden", color: .orange))
        }

        if let first = s.firstTripDate {
            let days = Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 0
            if days > 0 {
                facts.append(FunFact(icon: "hourglass", title: "Journey", detail: "\(days) days since\nfirst trip", color: .indigo))
            }
        }

        return facts
    }
}

// MARK: - Subviews

struct StreakPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct MiniStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let progress: Double?

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            ProgressView(value: progress ?? 0)
                .tint(color)
                .scaleEffect(y: 1.5)
                .opacity(progress != nil ? 1 : 0)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct CompletionRing: View {
    let progress: Double
    let label: String
    let detail: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 8)
                    .frame(width: 64, height: 64)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }

            Text(label)
                .font(.caption.bold())

            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecordCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct DayOfWeekChart: View {
    let data: [Int]
    private let days = ["M", "T", "W", "T", "F", "S", "S"]
    private var maxVal: Int { data.max() ?? 1 }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(i < 5 ? Color.blue : Color.orange)
                        .frame(height: barHeight(data[i]))

                    Text(days[i])
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 60)
    }

    private func barHeight(_ value: Int) -> CGFloat {
        guard maxVal > 0 else { return 4 }
        return max(4, CGFloat(value) / CGFloat(maxVal) * 44)
    }
}

struct FunFactCard: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(title)
                .font(.caption.bold())

            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .frame(width: 120, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SetOverviewRow: View {
    let set: FleetSet
    let stats: FleetStats.SetStats?
    @ObservedObject var imageStore: FleetImageStore

    private var progress: Double {
        guard let s = stats, s.totalTrains > 0 else { return 0 }
        return Double(s.trainsRidden) / Double(s.totalTrains)
    }

    var body: some View {
        HStack(spacing: 14) {
            TrainSetImageView(setName: set.name, size: 44, imageStore: imageStore)
                .overlay(
                    Circle().stroke(progressColor, lineWidth: 2.5)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(set.name)
                        .font(.subheadline.bold())

                    if progress >= 1.0 {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }

                    Spacer()

                    if let s = stats, s.tripCount > 0 {
                        Text("\(s.tripCount)")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(.secondary)
                        + Text(" trips")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                HStack(spacing: 12) {
                    Text("\(stats?.trainsRidden ?? 0)/\(set.totalTrains) trains")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(stats?.carriagesRidden ?? 0)/\(set.totalCarriages) cars")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                ProgressView(value: progress)
                    .tint(progressColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }

    private var progressColor: Color {
        if progress >= 1.0 { return .green }
        if progress > 0 { return .blue }
        return .gray.opacity(0.3)
    }
}

struct RecentTripCard: View {
    let trip: FleetStats.RecentTrip

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: "tram.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(trip.trainName)
                        .font(.subheadline.bold())
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(trip.carriageCode)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Text(trip.setName)
                    if !trip.locationName.isEmpty {
                        Text("·")
                        Text(trip.locationName)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(trip.date.formattedTime())
                    .font(.caption.monospacedDigit())
                Text(trip.date.userFriendlyRelativeString())
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
    }
}

struct AchievementBadge: View {
    let achievement: AchievementManager.Achievement
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundStyle(unlocked ? .yellow : .gray)
                .frame(width: 48, height: 48)
                .background(unlocked ? Color.yellow.opacity(0.15) : Color.gray.opacity(0.1), in: Circle())

            Text(achievement.title)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 70)
        }
    }
}

// MARK: - Train Set Image View

struct TrainSetImageView: View {
    let setName: String
    let size: CGFloat
    @ObservedObject var imageStore: FleetImageStore

    var body: some View {
        Group {
            if let img = imageStore.image(for: setName) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .overlay {
                        Image(systemName: "tram.fill")
                            .font(.system(size: size * 0.35))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
