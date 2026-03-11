//
//  AchievementsView.swift
//  TrainTrack Sydney
//

import SwiftUI

struct AchievementsView: View {

    @ObservedObject private var store = FleetStore.shared

    var body: some View {
        List {
            ForEach(AchievementManager.Achievement.Category.allCases, id: \.self) { category in
                let achievements = AchievementManager.all.filter { $0.category == category }
                Section {
                    ForEach(achievements, id: \.id) { achievement in
                        AchievementRow(
                            achievement: achievement,
                            unlocked: AchievementManager.shared.isUnlocked(achievement.id),
                            unlockedDate: AchievementManager.shared.unlockDate(achievement.id),
                            current: AchievementManager.shared.currentValue(for: achievement, fleet: store.fleet, stats: store.stats),
                            target: achievement.target
                        )
                    }
                } header: {
                    HStack {
                        Text(category.rawValue)
                        Spacer()
                        let count = achievements.filter { AchievementManager.shared.isUnlocked($0.id) }.count
                        Text("\(count)/\(achievements.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Achievements")
    }
}

struct AchievementRow: View {
    let achievement: AchievementManager.Achievement
    let unlocked: Bool
    let unlockedDate: Date?
    let current: Int
    let target: Int

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(unlocked ? iconColor.opacity(0.15) : Color.gray.opacity(0.08))
                    .frame(width: 48, height: 48)

                Image(systemName: achievement.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(unlocked ? iconColor : .gray.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(unlocked ? .primary : .secondary)

                    if unlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if !unlocked && target > 0 {
                    HStack(spacing: 8) {
                        ProgressView(value: progress)
                            .tint(progressColor)

                        Text("\(current)/\(target)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                } else if let date = unlockedDate {
                    Text("Unlocked \(date.userFriendlyRelativeString())")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(unlocked ? 1.0 : 0.7)
    }

    private var iconColor: Color {
        switch achievement.category {
        case .milestones: return .blue
        case .exploration: return .green
        case .completion: return .orange
        case .dedication: return .purple
        case .special: return .yellow
        }
    }

    private var progressColor: Color {
        if progress >= 0.75 { return .green }
        if progress >= 0.5 { return .orange }
        return .blue
    }
}
