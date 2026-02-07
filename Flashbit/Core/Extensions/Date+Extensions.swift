import Foundation

extension Date {
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    func timeAgoDisplay() -> String {
        Self.relativeFormatter.localizedString(for: self, relativeTo: Date())
    }
}
