//
//  EnterCarriageView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 20/11/20.
//

import SwiftUI

struct EnterCarriageView: View {

    @Binding var showingSheet: Bool
    @StateObject private var manager = EnteredCarriageManager()
    @FocusState private var isFieldFocused: Bool
    @ObservedObject private var store = FleetStore.shared

    private let tripManager = TripManager()

    @State private var showingSaved = false
    @State private var savedCode = ""

    var body: some View {
        Form {
            Section {
                TextField("Carriage code", text: $manager.enteredText)
                    .focused($isFieldFocused)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .submitLabel(.search)
            } header: {
                Text("Enter Carriage Code")
                    .textCase(.none)
                    .font(.subheadline)
            }

            if !manager.enteredText.isEmpty {
                Section {
                    if manager.results.isEmpty {
                        ContentUnavailableView {
                            Label("No Matches", systemImage: "magnifyingglass")
                        } description: {
                            Text("No carriages matching '\(manager.enteredText)'")
                        }
                        .listRowBackground(Color.clear)

                        // Allow logging unknown carriage codes
                        Button {
                            addTrip(code: manager.enteredText.uppercased())
                        } label: {
                            Label("Log '\(manager.enteredText.uppercased())' anyway", systemImage: "plus.circle")
                        }
                    } else {
                        ForEach(manager.results, id: \.train.name) { result in
                            CarriageSearchResultRow(
                                lookup: result,
                                stats: store.stats,
                                onSelect: { addTrip(code: result.train.carriages[result.position]) }
                            )
                        }
                    }
                } header: {
                    Text("\(manager.results.count) Result\(manager.results.count == 1 ? "" : "s")")
                }
            }
        }
        .navigationTitle("New Trip")
        .onAppear {
            isFieldFocused = true
            LocationManager.shared?.updateLocationName()
        }
        .overlay {
            if showingSaved {
                savedToast
            }
        }
    }

    private func addTrip(code: String) {
        guard !code.isEmpty else { return }
        do {
            try tripManager.addTrip(withCode: code)
            savedCode = code
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            withAnimation {
                showingSaved = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showingSheet = false
            }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private var savedToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Trip Saved — \(savedCode)")
                    .font(.subheadline.bold())
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .shadow(radius: 8)
            .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct CarriageSearchResultRow: View {
    let lookup: FleetStore.CarriageLookup
    let stats: FleetStats
    let onSelect: () -> Void

    private var code: String { lookup.train.carriages[lookup.position] }
    private var tripCount: Int { stats.carriageTripCounts[code] ?? 0 }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(code)
                        .font(.headline.monospaced())

                    Text(lookup.train.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(lookup.set.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if tripCount > 0 {
                        Text("\(tripCount) prior trips")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}
