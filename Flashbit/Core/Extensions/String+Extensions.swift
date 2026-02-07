import Foundation

extension String {
    /// Intelligently truncates text to fit within maxLength, preserving readability
    func smartTruncate(maxLength: Int) -> String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)

        // If already short enough, return as-is
        if trimmed.count <= maxLength {
            return trimmed
        }

        // Try to find a good sentence boundary within the limit
        let sentenceEndings: [Character] = [".", "!", "?"]
        var bestCut = 0

        for (index, char) in trimmed.enumerated() {
            if index >= maxLength - 10 { break } // Leave room for natural ending
            if sentenceEndings.contains(char) {
                // Check it's actually end of sentence (not abbreviation like "U.S.")
                let nextIndex = trimmed.index(trimmed.startIndex, offsetBy: index + 1, limitedBy: trimmed.endIndex)
                if let next = nextIndex, next < trimmed.endIndex {
                    let nextChar = trimmed[next]
                    if nextChar == " " || nextChar == "\n" {
                        bestCut = index + 1
                    }
                }
            }
        }

        // If we found a good sentence boundary, use it
        if bestCut > maxLength / 3 {
            return String(trimmed.prefix(bestCut))
        }

        // Try phrase boundaries (comma, semicolon, colon, dash)
        let phraseBreaks: [Character] = [",", ";", ":", "–", "—"]
        for (index, char) in trimmed.enumerated().reversed() {
            if index >= maxLength - 3 { continue }
            if index < maxLength / 2 { break }
            if phraseBreaks.contains(char) {
                let truncated = String(trimmed.prefix(index))
                return truncated + "..."
            }
        }

        // Last resort: cut at word boundary
        let cutoff = trimmed.prefix(maxLength - 3)
        if let lastSpace = cutoff.lastIndex(of: " ") {
            return String(cutoff[..<lastSpace]) + "..."
        }

        // Absolute fallback
        return String(trimmed.prefix(maxLength - 3)) + "..."
    }
}
