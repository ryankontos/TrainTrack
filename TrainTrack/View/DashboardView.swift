//
//  DashboardView.swift
//  TrainTrack
//

import SwiftUI
import CoreData

struct DashboardView: View {

    @ObservedObject private var store = FleetStore.shared
    @ObservedObject private var imageStore = FleetImageStore.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard

                    quickStatsGrid

                    if !store.fleet.sets.isEmpty {
                        fleetOverview
                    }

                    if !store.stats.recentTrips.isEmpty {
                        recentActivity
                    }

                    achievementsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("TrainTrack")
            .refreshable {
                store.load()
            }
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(spacing: 8) {
            Text("\(store.stats.totalTrips)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)

            Text("Total Trips")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let recent = store.stats.recentTrips.first {
                Text("Last: \(recent.carriageCode) (\(recent.setName)) — \(recent.date.userFriendlyRelativeString())")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Quick Stats Grid

    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "This Week", value: "\(store.stats.tripsThisWeek)", icon: "calendar", color: .orange)
            StatCard(title: "This Month", value: "\(store.stats.tripsThisMonth)", icon: "calendar.circle", color: .purple)
            StatCard(title: "Sets Ridden", value: "\(store.stats.setsRidden)/\(store.stats.totalSets)", icon: "tram.fill", color: .blue)
            StatCard(title: "Trains Ridden", value: "\(store.stats.trainsRidden)", icon: "train.side.front.car", color: .green)
            StatCard(title: "Carriages", value: "\(store.stats.carriagesRidden)", icon: "train.side.middle.car", color: .cyan)
            StatCard(title: "Most Ridden", value: store.stats.mostRiddenSetName, icon: "star.fill", color: .yellow)
        }
        .padding(.horizontal)
    }

    // MARK: - Fleet Overview

    private var fleetOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fleet Overview")
                .font(.title3.bold())
                .padding(.horizontal)

            ForEach(store.fleet.sets) { set in
                let setStats = store.stats.setStats[set.code]
                SetOverviewRow(set: set, stats: setStats, imageStore: imageStore)
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.title3.bold())
                .padding(.horizontal)

            ForEach(store.stats.recentTrips) { trip in
                RecentTripCard(trip: trip)
            }
        }
    }

    // MARK: - Achievements

    @ViewBuilder
    private var achievementsSection: some View {
        let unlockedIds = AchievementManager.shared.unlocked
        let unlockedAchievements = AchievementManager.all.filter { unlockedIds[$0.id] != nil }

        if !unlockedAchievements.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Achievements")
                    .font(.title3.bold())
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(unlockedAchievements, id: \.id) { a in
                            AchievementBadge(achievement: a, unlocked: true)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Subviews

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
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

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(set.name)
                        .font(.subheadline.bold())
                    Spacer()
                    Text("\(stats?.trainsRidden ?? 0)/\(set.totalTrains)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: progress)
                    .tint(progressColor)

                HStack(spacing: 8) {
                    if let s = stats, s.tripCount > 0 {
                        Label("\(s.tripCount) trips", systemImage: "number")
                    }
                    if set.yearIntroduced > 0 {
                        Label("Since \(String(set.yearIntroduced))", systemImage: "calendar")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
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
                Text(trip.carriageCode)
                    .font(.subheadline.bold())
                HStack(spacing: 4) {
                    Text(trip.setName)
                    if !trip.locationName.isEmpty && trip.locationName != "Unknown" {
                        Text("•")
                        Text(trip.locationName)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(trip.date.formattedTime())
                .font(.caption.monospacedDigit())
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
