//
//  TrainDataDownloader.swift
//  TrainTrack Sydney
//
//  Created by Ryan on 11/4/2024.
//

import Foundation
import Kanna
import os.log

private let logger = Logger(subsystem: "com.ryankontos.traintrack", category: "TrainDataDownloader")

// MARK: - Parsed Train

struct ParsedTrain: Codable {
    let setCode: String
    let carriages: [String]
    var builder: String?
    var depot: String?
    var notes: String?
    var status: TrainStatus = .active

    static func inferStatus(from notes: String?) -> TrainStatus {
        guard let text = notes?.lowercased() else { return .active }
        if text.contains("withdrawn") || text.contains("scrapped") || text.contains("decommission") || text.contains("written off") {
            return .withdrawn
        }
        if text.contains("stored") || text.contains("mothball") {
            return .stored
        }
        if text.contains("damaged") || text.contains("fire") || text.contains("collision") || text.contains("derail") {
            return .damaged
        }
        return .active
    }
}

// MARK: - Downloader

final class TrainDataDownloader {

    private static let fleetAPIURL = "https://nswtrains.fandom.com/api.php?action=parse&page=List_of_Sydney_Trains/NSW_TrainLink_fleets&format=json&prop=text"
    private static let cacheMaxAge: TimeInterval = 7 * 24 * 60 * 60

    // MARK: - File Paths

    private static var cacheDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("FleetCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static var cacheFileURL: URL {
        cacheDirectory.appendingPathComponent("fleet_trains.json")
    }

    private static var cacheMetadataURL: URL {
        cacheDirectory.appendingPathComponent("cache_meta.json")
    }

    // MARK: - Public API

    /// Synchronous load from disk cache. Returns nil if no cache exists.
    func loadCachedTrains() -> [ParsedTrain]? {
        guard FileManager.default.fileExists(atPath: Self.cacheFileURL.path) else { return nil }
        guard let data = try? Data(contentsOf: Self.cacheFileURL) else { return nil }
        return try? JSONDecoder().decode([ParsedTrain].self, from: data)
    }

    /// Async fetch from wiki. Saves to cache on success.
    func fetchFromWiki() async -> [ParsedTrain] {
        // Skip if cache is fresh
        if !isCacheStale(), let cached = loadCachedTrains() {
            return cached
        }

        guard let url = URL(string: Self.fleetAPIURL) else {
            logger.error("Invalid fleet API URL")
            return []
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                logger.error("Fleet API returned invalid response")
                return loadCachedTrains() ?? []
            }

            // Parse JSON wrapper: { "parse": { "text": { "*": "<html>..." } } }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let parse = json["parse"] as? [String: Any],
                  let text = parse["text"] as? [String: Any],
                  let htmlString = text["*"] as? String,
                  let htmlData = htmlString.data(using: .utf8) else {
                logger.error("Failed to extract HTML from API response")
                return loadCachedTrains() ?? []
            }

            let parsed = parseHTML(data: htmlData)

            if !parsed.isEmpty {
                saveToCache(parsed)
                logger.info("Fetched and cached \(parsed.count) trains from wiki API")
            } else {
                logger.warning("Wiki API parse returned empty — page structure may have changed")
            }

            return parsed
        } catch {
            logger.error("Fleet API request failed: \(error.localizedDescription)")
            return loadCachedTrains() ?? []
        }
    }

    // MARK: - HTML Parsing

    private func parseHTML(data: Data) -> [ParsedTrain] {
        guard let htmlString = String(data: data, encoding: .utf8),
              let doc = try? Kanna.HTML(html: htmlString, encoding: .utf8) else {
            logger.error("Failed to parse HTML")
            return []
        }

        var trains = [ParsedTrain]()

        for table in doc.css("table.wikitable") {
            var currentBuilder: (value: String, remaining: Int) = ("", 0)
            var currentDepot: (value: String, remaining: Int) = ("", 0)

            for row in table.css("tr") {
                guard row.css("th").count == 0 else { continue }

                let allCells = row.css("td")
                guard allCells.count >= 2 else { continue }

                let setCode = allCells[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let consistText = allCells[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                guard setCode.count <= 4, !setCode.isEmpty, setCode.first?.isLetter == true else { continue }

                let carriages = consistText.components(separatedBy: " - ")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty && $0.count <= 9 }

                guard !carriages.isEmpty else { continue }

                var cellIndex = 2
                var builder: String?
                var depot: String?
                var notes: String?

                for td in allCells.dropFirst(2) {
                    let text = td.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let rowspan = Int(td["rowspan"] ?? "1") ?? 1

                    if cellIndex == 2 && currentBuilder.remaining <= 0 {
                        currentBuilder = (text, rowspan)
                    } else if cellIndex == 2 && currentBuilder.remaining > 0 {
                        if currentDepot.remaining <= 0 {
                            currentDepot = (text, rowspan)
                        } else {
                            notes = text
                        }
                    }

                    if cellIndex == 3 && currentDepot.remaining <= 0 {
                        currentDepot = (text, rowspan)
                    } else if cellIndex == 3 {
                        notes = text
                    }

                    if cellIndex == 4 {
                        notes = text
                    }

                    cellIndex += 1
                }

                builder = currentBuilder.value.isEmpty ? nil : currentBuilder.value
                depot = currentDepot.value.isEmpty ? nil : currentDepot.value
                currentBuilder.remaining -= 1
                currentDepot.remaining -= 1

                if notes == nil && allCells.count > 2 {
                    let lastText = allCells[allCells.count - 1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !lastText.isEmpty && lastText != builder && lastText != depot {
                        notes = lastText
                    }
                }

                trains.append(ParsedTrain(
                    setCode: setCode,
                    carriages: carriages,
                    builder: builder,
                    depot: depot,
                    notes: (notes?.isEmpty ?? true) ? nil : notes,
                    status: ParsedTrain.inferStatus(from: notes)
                ))
            }
        }

        return trains
    }

    // MARK: - File Cache

    private func saveToCache(_ trains: [ParsedTrain]) {
        do {
            let data = try JSONEncoder().encode(trains)
            try data.write(to: Self.cacheFileURL, options: .atomic)

            let meta = CacheMetadata(lastUpdated: Date())
            let metaData = try JSONEncoder().encode(meta)
            try metaData.write(to: Self.cacheMetadataURL, options: .atomic)
        } catch {
            logger.error("Failed to save fleet cache: \(error.localizedDescription)")
        }
    }

    private func isCacheStale() -> Bool {
        guard let data = try? Data(contentsOf: Self.cacheMetadataURL),
              let meta = try? JSONDecoder().decode(CacheMetadata.self, from: data) else {
            return true
        }
        return Date().timeIntervalSince(meta.lastUpdated) > Self.cacheMaxAge
    }

    private struct CacheMetadata: Codable {
        let lastUpdated: Date
    }
}
