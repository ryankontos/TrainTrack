//
//  ContentView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import SwiftUI

struct ContentView: View {

    @State private var selectedTab = 0
    @State private var showingNewTrip = false

    var body: some View {
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
                    Text("Trains")
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
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button {
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
                .padding(.bottom, 60)
                .padding(.trailing, 20)
            }
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
