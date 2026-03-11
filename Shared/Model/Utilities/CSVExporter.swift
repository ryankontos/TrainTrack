//
//  CSVExporter.swift
//  TrainTrack
//

import UIKit
import CoreData

struct CSVExporter {

    @MainActor
    static func exportTrips() {
        let context = TTCloudKit.shared.persistentContainer.viewContext
        let request: NSFetchRequest<StoredTrip> = StoredTrip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredTrip.date, ascending: false)]

        if let archiveId = TTCloudKit.shared.activeArchiveId {
            request.predicate = NSPredicate(format: "archiveId == %@", archiveId as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "archiveId == nil")
        }

        guard let trips = try? context.fetch(request) else { return }
        let csv = generateCSV(from: trips)
        shareCSV(csv)
    }

    @MainActor
    static func generateCSV(from trips: [StoredTrip]) -> String {
        var rows = ["Date,Time,Carriage Code,Train,Set,Set Type,Location,Latitude,Longitude,Notes"]
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm:ss"

        let store = FleetStore.shared

        for trip in trips {
            let date = trip.date.map { dateFmt.string(from: $0) } ?? ""
            let time = trip.date.map { timeFmt.string(from: $0) } ?? ""
            let code = trip.carriageCode ?? ""
            let lookup = store.findTrain(byCarriage: code)
            let train = lookup?.train.name ?? ""
            let setName = lookup?.set.name ?? ""
            let setCode = lookup?.set.code ?? ""
            let location = trip.locationName ?? ""
            let lat = trip.latitude != 0 ? String(trip.latitude) : ""
            let lon = trip.longitude != 0 ? String(trip.longitude) : ""
            let notes = (trip.notes ?? "").replacingOccurrences(of: ",", with: ";")

            rows.append("\(date),\(time),\(code),\(train),\(setName),\(setCode),\(escape(location)),\(lat),\(lon),\(escape(notes))")
        }

        return rows.joined(separator: "\n")
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }

    private static func shareCSV(_ csv: String) {
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        let fileName = "TrainTrack_Export_\(dateFmt.string(from: Date())).csv"

        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? csv.write(to: tmpURL, atomically: true, encoding: .utf8)

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }

        let vc = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
        if let popover = vc.popoverPresentationController {
            popover.sourceView = root.view
            popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
        }
        root.present(vc, animated: true)
    }
}
