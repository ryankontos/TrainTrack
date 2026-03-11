//
//  TrainHeaderView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 21/11/20.
//

import SwiftUI

struct TrainHeaderView: View {

    let train: FleetTrain
    let set: FleetSet
    var carriage: String?
    @Binding var showingSheet: Bool
    @State private var added = false
    @ObservedObject private var imageStore = FleetImageStore.shared

    private let tripManager = TripManager()

    var body: some View {
        HStack(spacing: 16) {
            TrainSetImageView(setName: set.name, size: 80, imageStore: imageStore)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(train.name)
                    .font(.system(size: 22, weight: .semibold))

                Text(set.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let code = carriage {
                    Button {
                        guard !added else { return }
                        withAnimation { added = true }

                        do {
                            try tripManager.addTrip(withCode: code)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        } catch {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showingSheet = false
                        }
                    } label: {
                        AddTripCapsule(added: $added)
                    }
                    .disabled(added)
                }
            }

            Spacer()
        }
    }
}
