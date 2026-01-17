import Foundation
import NaturalLanguage

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Service for AI-powered text summarization
actor SummarizationService {
    static let shared = SummarizationService()

    private var cache: [String: String] = [:]

    /// Summarizes text to fit in approximately 2-3 lines while preserving key information
    func summarize(_ text: String, maxLength: Int = 140) async -> String {
        // Check cache first
        let cacheKey = "\(text.hashValue)_\(maxLength)"
        if let cached = cache[cacheKey] {
            return cached
        }

        // Skip if already short enough
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= maxLength {
            return trimmed
        }

        // Try AI summarization on iOS 18.4+
        if #available(iOS 26.0, *) {
            #if canImport(FoundationModels)
            if let aiSummary = await summarizeWithFoundationModels(trimmed, maxLength: maxLength) {
                cache[cacheKey] = aiSummary
                return aiSummary
            }
            #endif
        }

        // Fallback to smart truncation
        let fallback = trimmed.smartTruncate(maxLength: maxLength)
        cache[cacheKey] = fallback
        return fallback
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func summarizeWithFoundationModels(_ text: String, maxLength: Int) async -> String? {
        do {
            let session = LanguageModelSession()

            let prompt = """
            Summarize this news snippet in one concise sentence (max \(maxLength) characters). \
            Keep the key facts and make it engaging. Do not start with "This article" or similar. \
            Just give the summary, nothing else:

            \(text)
            """

            let response = try await session.respond(to: prompt)
            let summary = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

            // Validate the response
            if summary.count > 0 && summary.count <= maxLength + 20 {
                // Trim if slightly over
                if summary.count > maxLength {
                    return summary.smartTruncate(maxLength: maxLength)
                }
                return summary
            }

            return nil
        } catch {
            print("Foundation Models summarization failed: \(error)")
            return nil
        }
    }
    #endif

    /// Clears the summarization cache
    func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Batch Summarization

extension SummarizationService {
    /// Summarizes multiple texts concurrently
    func summarizeBatch(_ texts: [String], maxLength: Int = 140) async -> [String] {
        await withTaskGroup(of: (Int, String).self) { group in
            for (index, text) in texts.enumerated() {
                group.addTask {
                    let summary = await self.summarize(text, maxLength: maxLength)
                    return (index, summary)
                }
            }

            var results = Array(repeating: "", count: texts.count)
            for await (index, summary) in group {
                results[index] = summary
            }
            return results
        }
    }
}
