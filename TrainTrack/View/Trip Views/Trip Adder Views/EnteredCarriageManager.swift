//
//  EnteredCarriageManager.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 23/1/2022.
//

import Foundation
import SwiftUI

@MainActor
class EnteredCarriageManager: ObservableObject {

    @Published var enteredText: String = "" {
        didSet { updateResults() }
    }

    @Published var results = [FleetStore.CarriageLookup]()

    func gotFullCarriageCodeExternally(code: String) {
        enteredText = code
    }

    private func updateResults() {
        results = FleetStore.shared.searchCarriages(prefix: enteredText)
    }
}
