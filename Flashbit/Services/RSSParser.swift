import Foundation

/// Parsed RSS item from a feed
struct RSSItem {
    let title: String
    let description: String
    let link: String
    let pubDate: String
    let imageURL: String?
}

/// RSS feed parser using XMLParser
class RSSParser: NSObject, XMLParserDelegate {
    private var items: [RSSItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentImageURL: String?
    private var currentImageWidth: Int = 0
    private var isInsideItem = false

    /// Parses RSS XML data and returns an array of RSSItems
    func parse(data: Data) -> [RSSItem] {
        items = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return items
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName

        if elementName == "item" {
            isInsideItem = true
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentPubDate = ""
            currentImageURL = nil
            currentImageWidth = 0
        }

        // Handle media:content and enclosure for images
        // Prefer larger images when multiple are available
        if isInsideItem {
            if elementName == "media:content" || elementName == "media:thumbnail" {
                if let url = attributeDict["url"] {
                    let width = Int(attributeDict["width"] ?? "0") ?? 0
                    // Take this image if it's larger than what we have, or if we have none
                    if width > currentImageWidth || currentImageURL == nil {
                        currentImageURL = url
                        currentImageWidth = max(width, 1)
                    }
                }
            } else if elementName == "enclosure" {
                if let type = attributeDict["type"], type.starts(with: "image/"),
                   let url = attributeDict["url"] {
                    // Enclosures are usually full-size, prefer them
                    if currentImageWidth < 1000 {
                        currentImageURL = url
                        currentImageWidth = 1000
                    }
                }
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInsideItem else { return }

        switch currentElement {
        case "title":
            currentTitle += string
        case "description", "content:encoded":
            currentDescription += string
        case "link":
            currentLink += string
        case "pubDate":
            currentPubDate += string
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            // If no image found in media tags, try to extract from description HTML
            var finalImageURL = currentImageURL
            if finalImageURL == nil {
                finalImageURL = extractImageFromHTML(currentDescription)
            }

            // Enhance image URL for better quality
            if let url = finalImageURL {
                finalImageURL = enhanceImageURL(url)
            }

            let item = RSSItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: stripHTML(from: currentDescription).trimmingCharacters(in: .whitespacesAndNewlines),
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines),
                imageURL: finalImageURL
            )
            items.append(item)
            isInsideItem = false
        }
    }

    /// Extracts first image URL from HTML content
    private func extractImageFromHTML(_ html: String) -> String? {
        // Look for img src in HTML
        let pattern = "<img[^>]+src=[\"']([^\"']+)[\"']"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(html.startIndex..., in: html)
        if let match = regex.firstMatch(in: html, options: [], range: range),
           let urlRange = Range(match.range(at: 1), in: html) {
            return String(html[urlRange])
        }
        return nil
    }

    /// Enhances image URL to get higher resolution versions for known sources
    private func enhanceImageURL(_ url: String) -> String {
        var enhanced = url

        // BBC: Replace thumbnail sizes with larger versions
        // e.g., /news/624 -> /news/976 or /news/1024
        if url.contains("bbci.co.uk") || url.contains("bbc.co.uk") {
            enhanced = enhanced.replacingOccurrences(of: "/96/", with: "/800/")
            enhanced = enhanced.replacingOccurrences(of: "/128/", with: "/800/")
            enhanced = enhanced.replacingOccurrences(of: "/240/", with: "/800/")
            enhanced = enhanced.replacingOccurrences(of: "/320/", with: "/800/")
            enhanced = enhanced.replacingOccurrences(of: "/464/", with: "/800/")
            enhanced = enhanced.replacingOccurrences(of: "/624/", with: "/976/")
        }

        // Guardian: Request larger images
        // e.g., width=140 -> width=1000
        if url.contains("guim.co.uk") || url.contains("guardian") {
            if let widthRange = enhanced.range(of: "width=\\d+", options: .regularExpression) {
                enhanced = enhanced.replacingCharacters(in: widthRange, with: "width=1000")
            }
        }

        // TechCrunch/WordPress: Request larger sizes
        // e.g., ?w=150 -> ?w=1200 or -150x150. -> -1200x630.
        if url.contains("techcrunch") || url.contains("wp.com") || url.contains("wordpress") {
            if let wRange = enhanced.range(of: "[?&]w=\\d+", options: .regularExpression) {
                enhanced = enhanced.replacingCharacters(in: wRange, with: "?w=1200")
            }
            // Replace WordPress thumbnail sizes like -150x150.jpg with full size
            enhanced = enhanced.replacingOccurrences(
                of: "-\\d+x\\d+\\.",
                with: ".",
                options: .regularExpression
            )
        }

        return enhanced
    }

    /// Strips HTML tags from a string
    private func stripHTML(from string: String) -> String {
        // Decode common HTML entities
        var result = string
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&#160;", with: " ")

        // Strip HTML tags using regex
        result = result.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Clean up extra whitespace
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return result
    }

    /// Parses an RSS date string into a Date object
    static func parseDate(_ dateString: String) -> Date {
        let formatters: [DateFormatter] = [
            {
                let df = DateFormatter()
                df.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
                df.locale = Locale(identifier: "en_US_POSIX")
                return df
            }(),
            {
                let df = DateFormatter()
                df.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                df.locale = Locale(identifier: "en_US_POSIX")
                return df
            }(),
            {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                df.locale = Locale(identifier: "en_US_POSIX")
                return df
            }()
        ]

        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return Date()
    }
}
