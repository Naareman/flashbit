import SwiftUI

enum BitCategory: String, Codable, CaseIterable, Sendable {
    case breaking = "Breaking"
    case tech = "Tech"
    case business = "Business"
    case sports = "Sports"
    case entertainment = "Entertainment"
    case science = "Science"
    case health = "Health"
    case world = "World"

    var color: Color {
        switch self {
        case .breaking: return .red
        case .tech: return .blue
        case .business: return .green
        case .sports: return .orange
        case .entertainment: return .purple
        case .science: return .cyan
        case .health: return .pink
        case .world: return .indigo
        }
    }

    var iconName: String {
        switch self {
        case .breaking: return "exclamationmark.triangle.fill"
        case .tech: return "cpu.fill"
        case .business: return "chart.line.uptrend.xyaxis"
        case .sports: return "sportscourt.fill"
        case .entertainment: return "film.fill"
        case .science: return "atom"
        case .health: return "heart.fill"
        case .world: return "globe"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .breaking: return [.red, .orange]
        case .tech: return [.blue, .purple]
        case .business: return [.green, .teal]
        case .sports: return [.orange, .yellow]
        case .entertainment: return [.purple, .pink]
        case .science: return [.cyan, .blue]
        case .health: return [.pink, .red]
        case .world: return [.indigo, .blue]
        }
    }
}
