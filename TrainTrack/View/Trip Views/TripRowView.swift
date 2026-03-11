//
//  TripRowView.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import SwiftUI

struct TripRowView: View {

    let trip: StoredTrip
    let showDate: Bool

    @ObservedObject private var store = FleetStore.shared

    private var code: String { trip.carriageCode ?? "Unknown" }

    private var lookup: FleetStore.CarriageLookup? {
        store.findTrain(byCarriage: code)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: "tram.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)

                Text(setName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text("\(dateString) • \(trip.locationName ?? "Unknown Location")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private var title: String {
        if let trainName = lookup?.train.name {
            return "\(trainName) • \(code)"
        }
        return code
    }

    private var setName: String {
        lookup?.set.name ?? "Unknown Set"
    }

    private var dateString: String {
        guard let date = trip.date else { return "Unknown Time" }
        if showDate {
            return "\(date.formattedDate()), \(date.formattedTime())"
        }
        return date.formattedTime()
    }
}
