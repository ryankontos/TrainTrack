/*
See LICENSE folder for this sample's licensing information.

Abstract:
Utilities for dealing with recognized strings
*/

import Foundation

extension Character {
    func getSimilarCharacterIfNotIn(allowedChars: String) -> Character {
        let conversionTable = [
            "s": "S", "S": "5", "5": "S",
            "o": "O", "Q": "O", "O": "0", "0": "O",
            "l": "I", "I": "1", "1": "I",
            "B": "8", "8": "B"
        ]
        let maxSubstitutions = 2
        var current = String(self)
        var counter = 0
        while !allowedChars.contains(current) && counter < maxSubstitutions {
            if let altChar = conversionTable[current] {
                current = altChar
                counter += 1
            } else {
                break
            }
        }
        return current.first!
    }
}

extension String {
    @MainActor
    func extractCarriageCode() -> (Range<String.Index>, String)? {
        let allCodes = FleetStore.shared.allCarriageCodes

        for code in allCodes {
            if let range = self.range(of: code, options: [.caseInsensitive, .widthInsensitive]) {
                return (range, code)
            }
        }

        return nil
    }
}

class StringTracker {
    var frameIndex: Int64 = 0

    typealias StringObservation = (lastSeen: Int64, count: Int64)

    var seenStrings = [String: StringObservation]()
    var bestCount = Int64(0)
    var bestString = ""

    func logFrame(strings: [String]) {
        for string in strings {
            if seenStrings[string] == nil {
                seenStrings[string] = (lastSeen: Int64(0), count: Int64(-1))
            }
            seenStrings[string]?.lastSeen = frameIndex
            seenStrings[string]?.count += 1
        }

        var obsoleteStrings = [String]()

        for (string, obs) in seenStrings {
            if obs.lastSeen < frameIndex - 30 {
                obsoleteStrings.append(string)
            }

            let count = obs.count
            if !obsoleteStrings.contains(string) && count > bestCount {
                bestCount = Int64(count)
                bestString = string
            }
        }
        for string in obsoleteStrings {
            seenStrings.removeValue(forKey: string)
        }

        frameIndex += 1
    }

    func getStableString() -> String? {
        if bestCount >= 10 {
            return bestString
        } else {
            return nil
        }
    }

    func reset(string: String) {
        seenStrings.removeValue(forKey: string)
        bestCount = 0
        bestString = ""
    }
}
