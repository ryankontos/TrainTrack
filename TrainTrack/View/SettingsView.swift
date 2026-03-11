//
//  SettingsView.swift
//  TrainTrack Sydney
//

import SwiftUI

struct SettingsView: View {

    @StateObject private var archiveManager = ArchiveManager.shared
    @ObservedObject private var store = FleetStore.shared
    @State private var showingNewArchive = false
    @State private var newArchiveName = ""
    @State private var showingRefreshAlert = false

    private var fleetInfo: String {
        let f = store.fleet
        guard !f.sets.isEmpty else { return "Not loaded" }
        return "\(f.totalTrains) trains · \(f.totalCarriages) carriages"
    }

    var body: some View {
        NavigationStack {
            List {
                // Quick stats summary
                if store.stats.totalTrips > 0 {
                    Section {
                        HStack(spacing: 0) {
                            QuickStat(value: "\(store.stats.totalTrips)", label: "Trips", icon: "number", color: .blue)
                            QuickStat(value: "\(store.stats.trainsRidden)", label: "Trains", icon: "train.side.front.car", color: .green)
                            QuickStat(value: "\(store.stats.carriagesRidden)", label: "Cars", icon: "train.side.middle.car", color: .cyan)
                            QuickStat(value: "\(store.stats.currentStreak)", label: "Streak", icon: "flame.fill", color: .orange)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }

                // Achievements
                Section {
                    NavigationLink {
                        AchievementsView()
                    } label: {
                        Label {
                            HStack {
                                Text("Achievements")
                                Spacer()
                                let count = AchievementManager.shared.unlocked.count
                                let total = AchievementManager.all.count
                                Text("\(count)/\(total)")
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                }

                // Archives
                Section {
                    ForEach(archiveManager.archives, id: \.id) { archive in
                        ArchiveRow(
                            archive: archive,
                            isActive: archive.isActive,
                            onSwitch: {
                                archiveManager.switchToArchive(archive.id)
                            }
                        )
                    }

                    Button {
                        showingNewArchive = true
                    } label: {
                        Label("New Archive", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Archives")
                } footer: {
                    Text("Archives let you freeze your trip history and start fresh. Switch between archives to compare different time periods.")
                }

                // Data
                Section("Data") {
                    Button {
                        CSVExporter.exportTrips()
                    } label: {
                        Label("Export Trips as CSV", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        store.load()
                        showingRefreshAlert = true
                    } label: {
                        Label("Refresh Fleet Data", systemImage: "arrow.clockwise")
                    }
                }

                // Fleet info
                Section("Fleet Data") {
                    LabeledContent("Source", value: "NSW Trains Wiki")
                    LabeledContent("Fleet Types", value: "\(store.fleet.sets.count)")
                    LabeledContent("Total Trains", value: "\(store.fleet.totalTrains)")
                    LabeledContent("Active", value: "\(store.fleet.activeTrains)")
                    LabeledContent("Retired", value: "\(store.fleet.retiredTrains)")
                    LabeledContent("Total Carriages", value: "\(store.fleet.totalCarriages)")
                }

                // App info
                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                    LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—")
                    LabeledContent("Sync", value: "iCloud")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More")
            .onAppear { archiveManager.reload() }
            .alert("New Archive", isPresented: $showingNewArchive) {
                TextField("Archive name", text: $newArchiveName)
                Button("Create") {
                    guard !newArchiveName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    archiveManager.createArchive(name: newArchiveName)
                    newArchiveName = ""
                }
                Button("Cancel", role: .cancel) { newArchiveName = "" }
            } message: {
                Text("Your current trips will be preserved. New trips will go into the new archive.")
            }
            .alert("Fleet Refreshed", isPresented: $showingRefreshAlert) {
                Button("OK") {}
            } message: {
                Text(fleetInfo)
            }
        }
    }
}

private struct QuickStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

struct ArchiveRow: View {
    let archive: ArchiveManager.ArchiveInfo
    let isActive: Bool
    let onSwitch: () -> Void

    var body: some View {
        Button(action: onSwitch) {
            HStack(spacing: 12) {
                Image(systemName: isActive ? "archivebox.fill" : "archivebox")
                    .foregroundStyle(isActive ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(archive.name)
                            .foregroundStyle(.primary)
                        if isActive {
                            Text("Active")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.12), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }

                    HStack(spacing: 8) {
                        Text("\(archive.tripCount) trips")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if archive.createdDate != .distantPast {
                            Text("·")
                                .foregroundStyle(.quaternary)
                            Text("Created \(archive.createdDate.userFriendlyRelativeString())")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
