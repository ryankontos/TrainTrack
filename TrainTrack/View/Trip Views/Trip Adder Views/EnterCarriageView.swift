//
//  EnterCarriageView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI
import CoreData

struct EnterCarriageView: View {

    @Binding var showingSheet: Bool
    @StateObject private var manager = EnteredCarriageManager()
    @FocusState private var isFieldFocused: Bool
    @ObservedObject private var store = FleetStore.shared
    @ObservedObject private var imageStore = FleetImageStore.shared

    private let tripManager = TripManager()

    @State private var showingSaved = false
    @State private var savedInfo: (code: String, train: String, set: String)?

    var body: some View {
        VStack(spacing: 0) {
            // Big prominent code field
            codeField

            if showingSaved, let info = savedInfo {
                successOverlay(info)
            } else if manager.enteredText.isEmpty {
                tipView
            } else {
                resultsList
            }
        }
        .navigationTitle("New Trip")
        .onAppear {
            isFieldFocused = true
            LocationManager.shared?.updateLocationName()
        }
    }

    // MARK: - Code Field

    private var codeField: some View {
        HStack(spacing: 10) {
            TextField("Carriage code", text: $manager.enteredText)
                .focused($isFieldFocused)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .submitLabel(.done)
                .onSubmit { logTopMatch() }

            if !manager.enteredText.isEmpty {
                Button { manager.enteredText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Tip (shown when field empty)

    private var tipView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "train.side.front.car")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("Type the code shown above the carriage doors")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let loc = LocationManager.shared?.currentLocationName, !loc.isEmpty {
                Label(loc, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Results

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if manager.results.isEmpty {
                    // No match — offer to log raw code
                    Button { logCode(manager.enteredText.uppercased()) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(manager.enteredText.uppercased())
                                    .font(.headline.monospaced())
                                Text("Log unknown carriage")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(Array(manager.results.prefix(15).enumerated()), id: \.element.train.name) { _, result in
                        ResultRow(result: result, stats: store.stats, imageStore: imageStore) {
                            logCode(result.train.carriages[result.position])
                        }
                        Divider().padding(.leading, 68)
                    }
                }
            }
        }
    }

    // MARK: - Success

    private func successOverlay(_ info: (code: String, train: String, set: String)) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text(info.code)
                .font(.title.bold().monospaced())

            Text("\(info.train) · \(info.set)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Actions

    private func logTopMatch() {
        if let first = manager.results.first {
            logCode(first.train.carriages[first.position])
        } else if !manager.enteredText.isEmpty {
            logCode(manager.enteredText.uppercased())
        }
    }

    private func logCode(_ code: String) {
        guard !code.isEmpty else { return }
        do {
            try tripManager.addTrip(withCode: code)
            let lookup = store.findTrain(byCarriage: code.uppercased())
            savedInfo = (code.uppercased(), lookup?.train.name ?? "Unknown", lookup?.set.name ?? "")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeInOut(duration: 0.25)) { showingSaved = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showingSheet = false }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Result Row

private struct ResultRow: View {
    let result: FleetStore.CarriageLookup
    let stats: FleetStats
    @ObservedObject var imageStore: FleetImageStore
    let onTap: () -> Void

    private var code: String { result.train.carriages[result.position] }
    private var priorTrips: Int { stats.carriageTripCounts[code] ?? 0 }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                TrainSetImageView(setName: result.set.name, size: 40, imageStore: imageStore)

                VStack(alignment: .leading, spacing: 2) {
                    Text(code)
                        .font(.headline.monospaced())
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Text(result.train.name)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(result.set.name)
                            .foregroundStyle(.tertiary)
                    }
                    .font(.caption)
                }

                Spacer()

                if priorTrips > 0 {
                    Text("\(priorTrips)×")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
