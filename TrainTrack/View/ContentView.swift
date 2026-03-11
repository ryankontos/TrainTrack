//
//  ContentView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject private var store = FleetStore.shared
    @State private var selectedTab = 0
    @State private var showingNewTrip = false
    @State private var loadingPhase: LoadingPhase = .loading

    fileprivate enum LoadingPhase {
        case loading, success, done
    }

    private var needsFirstLoad: Bool {
        store.fleet.sets.isEmpty
    }

    var body: some View {
        ZStack {
            mainContent
                .opacity(loadingPhase == .done ? 1 : 0)

            if loadingPhase != .done {
                FirstLoadView(phase: $loadingPhase, store: store)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: loadingPhase)
        .onChange(of: store.fleet.sets.isEmpty) { _, empty in
            if !empty && loadingPhase == .loading {
                withAnimation {
                    loadingPhase = .success
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    withAnimation {
                        loadingPhase = .done
                    }
                }
            }
        }
        .onAppear {
            if !needsFirstLoad {
                loadingPhase = .done
            }
        }
    }

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                    Text("Dashboard")
                }
                .tag(0)

            SetsList()
                .tabItem {
                    Image(systemName: "tram.fill")
                    Text("Fleet")
                }
                .tag(1)

            AllTripsView()
                .tabItem {
                    Image(systemName: "list.bullet.circle.fill")
                    Text("Trips")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("More")
                }
                .tag(3)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showingNewTrip = true
            } label: {
                ZStack {
                    Circle()
                        .fill(.blue)
                        .frame(width: 56, height: 56)
                        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 90)
        }
        .sheet(isPresented: $showingNewTrip) {
            NavigationStack {
                EnterCarriageView(showingSheet: $showingNewTrip)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingNewTrip = false }
                        }
                    }
            }
        }
    }
}

// MARK: - First Load View

private struct FirstLoadView: View {
    @Binding var phase: ContentView.LoadingPhase
    @ObservedObject var store: FleetStore

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var statusOpacity: Double = 0
    @State private var dotCount = 0
    @State private var dotTimer: Timer?

    private var isSuccess: Bool { phase == .success }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(isSuccess ? Color.green.opacity(0.12) : Color.blue.opacity(0.08))
                        .frame(width: 120, height: 120)

                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "tram.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(isSuccess ? .green : .blue)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                        .contentTransition(.symbolEffect(.replace))
                }

                VStack(spacing: 8) {
                    Text(isSuccess ? "Ready to Go!" : "TrainTrack")
                        .font(.title2.bold())
                        .contentTransition(.numericText())

                    Group {
                        if isSuccess {
                            let count = store.fleet.totalTrains
                            Text("Loaded \(count) trains across \(store.fleet.sets.count) fleet types")
                        } else {
                            Text("Fetching fleet data" + String(repeating: ".", count: dotCount))
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 20)
                }
                .opacity(statusOpacity)

                if !isSuccess {
                    ProgressView()
                        .controlSize(.regular)
                        .padding(.top, 4)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
                statusOpacity = 1.0
            }
            startDotAnimation()
        }
        .onDisappear {
            dotTimer?.invalidate()
        }
        .onChange(of: isSuccess) { _, success in
            if success {
                dotTimer?.invalidate()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    iconScale = 1.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        iconScale = 1.0
                    }
                }
            }
        }
    }

    private func startDotAnimation() {
        dotTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}
