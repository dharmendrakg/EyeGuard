import Foundation

enum OverlayTheme: String, CaseIterable, Identifiable, Codable {
    case minimal
    case fallingLeaves
    case snowfall
    case bubbles
    case starfield
    case rain
    case fireflies
    case sakura

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimal:       return "Minimal"
        case .fallingLeaves: return "Falling Leaves"
        case .snowfall:      return "Snowfall"
        case .bubbles:       return "Bubbles"
        case .starfield:     return "Starfield"
        case .rain:          return "Rain"
        case .fireflies:     return "Fireflies"
        case .sakura:        return "Sakura"
        }
    }

    var iconName: String {
        switch self {
        case .minimal:       return "circle.slash"
        case .fallingLeaves: return "leaf.fill"
        case .snowfall:      return "snowflake"
        case .bubbles:       return "circle.circle.fill"
        case .starfield:     return "sparkles"
        case .rain:          return "cloud.rain.fill"
        case .fireflies:     return "light.max"
        case .sakura:        return "tree"
        }
    }
}
