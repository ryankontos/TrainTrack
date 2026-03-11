//
//  FleetImageStore.swift
//  TrainTrack
//

import UIKit
import os.log

private let logger = Logger(subsystem: "com.ryankontos.traintrack", category: "FleetImages")

/// Fetches and caches train set images from Wikipedia.
@MainActor
final class FleetImageStore: ObservableObject {
    static let shared = FleetImageStore()

    @Published private(set) var images = [String: UIImage]()
    private var inProgress = Set<String>()

    // MARK: - Public

    /// Returns the cached image for a set, or triggers an async fetch.
    func image(for setName: String) -> UIImage? {
        if let img = images[setName] { return img }

        if let disk = loadFromDisk(setName) {
            images[setName] = disk
            return disk
        }

        guard !inProgress.contains(setName) else { return nil }
        inProgress.insert(setName)
        Task {
            await fetchAndCache(setName)
            inProgress.remove(setName)
        }
        return nil
    }

    /// Pre-warm all known set images.
    func preloadAll() {
        for def in SetDefinition.all {
            _ = image(for: def.name)
        }
    }

    // MARK: - Wikipedia API

    private func fetchAndCache(_ setName: String) async {
        guard let image = await fetchFromWikipedia(setName) else {
            logger.warning("No image found for '\(setName)'")
            return
        }
        saveToDisk(setName, image: image)
        images[setName] = image
        logger.info("Cached image for '\(setName)'")
    }

    private func fetchFromWikipedia(_ setName: String) async -> UIImage? {
        // 1. Try known article title
        if let def = SetDefinition.all.first(where: { $0.name == setName }) {
            if let image = await fetchPageImage(articleTitle: def.wikiArticle) {
                return image
            }
        }

        // 2. Fallback: search Wikipedia
        let query = "\(setName) Sydney train".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? setName
        return await fetchSearchImage(query: query)
    }

    private func fetchPageImage(articleTitle: String) async -> UIImage? {
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&titles=\(articleTitle)&prop=pageimages&piprop=thumbnail&pithumbsize=800&format=json"
        return await downloadWikipediaImage(from: urlString)
    }

    private func fetchSearchImage(query: String) async -> UIImage? {
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch=\(query)&gsrlimit=1&prop=pageimages&piprop=thumbnail&pithumbsize=800&format=json"
        return await downloadWikipediaImage(from: urlString)
    }

    private func downloadWikipediaImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let query = json["query"] as? [String: Any],
                  let pages = query["pages"] as? [String: Any] else { return nil }

            // Get the first page with a thumbnail
            for (_, pageValue) in pages {
                guard let page = pageValue as? [String: Any],
                      let thumbnail = page["thumbnail"] as? [String: Any],
                      let source = thumbnail["source"] as? String,
                      let imageURL = URL(string: source) else { continue }

                let (imageData, _) = try await URLSession.shared.data(from: imageURL)
                return UIImage(data: imageData)
            }
        } catch {
            logger.error("Wikipedia API error: \(error.localizedDescription)")
        }

        return nil
    }

    // MARK: - Disk Cache

    private static var imagesDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("FleetImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func imageFileURL(for setName: String) -> URL {
        let safeName = setName.replacingOccurrences(of: " ", with: "_")
        return Self.imagesDirectory.appendingPathComponent("\(safeName).jpg")
    }

    private func loadFromDisk(_ setName: String) -> UIImage? {
        let url = imageFileURL(for: setName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func saveToDisk(_ setName: String, image: UIImage) {
        let url = imageFileURL(for: setName)
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
