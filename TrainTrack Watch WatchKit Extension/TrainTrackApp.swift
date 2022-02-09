//
//  TrainTrackApp.swift
//  TrainTrack Watch WatchKit Extension
//
//  Created by Ryan Kontos on 24/1/2022.
//

import SwiftUI

@main
struct TrainTrackApp: App {
    
    init() {
        
        TrainFetcher.shared = TrainFetcher()
        
    }
    
    var body: some Scene {
        
        
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
