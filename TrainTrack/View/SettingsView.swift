//
//  SettingsView.swift
//  TrainTrack Sydney
//

import SwiftUI

struct SettingsView: View {

    @StateObject private var archiveManager = ArchiveManager.shared
    @State private var showingNewArchive = false
    @State private var newArchiveName = ""

    var body: some View {
        NavigationStack {
            List {
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
                    Text("Archives let you freeze your trip history and start fresh. Switch between archives to compare different periods.")
                }

                // Export
                Section("Data") {
                    Button {
                        CSVExporter.exportTrips()
                    } label: {
                        Label("Export Trips as CSV", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        FleetStore.shared.load()
                    } label: {
                        Label("Refresh Fleet Data", systemImage: "arrow.clockwise")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Fleet Data")
                        Spacer()
                        Text("NSW Trains Wiki")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                            .foregroundStyle(.secondary)
                    }
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
        }
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

                    Text("\(archive.tripCount) trips")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
