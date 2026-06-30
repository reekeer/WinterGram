import Foundation

public enum WinterGramBadgeLimits {
    public static let maxBadges = 64
    public static let maxLayers = 16
    public static let maxAssetBytes = 512 * 1024
}

public enum WinterGramBadgeTint: Equatable {
    case theme
    case hex(UInt32)
    case original

    public init(parsing raw: String?) {
        guard var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !s.isEmpty else {
            self = .theme
            return
        }
        if s == "theme" {
            self = .theme
        } else if s == "none" || s == "original" {
            self = .original
        } else {
            if s.hasPrefix("#") {
                s.removeFirst()
            }
            if s.count == 6, let value = UInt32(s, radix: 16) {
                self = .hex(value)
            } else {
                self = .theme
            }
        }
    }
}

public enum WinterGramBadgeAnimationType: String, Equatable {
    case none
    case rotate
    case blink
    case pulse
    case bounce
    case shake
    case lottie

    public init(parsing raw: String?) {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), let value = WinterGramBadgeAnimationType(rawValue: raw) else {
            self = .none
            return
        }
        self = value
    }
}

public struct WinterGramBadgeAnimation: Equatable, Decodable {
    public let type: WinterGramBadgeAnimationType
    public let duration: Double
    public let loop: Bool
    public let directionClockwise: Bool
    public let amplitude: Double

    public static let none = WinterGramBadgeAnimation(type: .none, duration: 0.0, loop: false, directionClockwise: true, amplitude: 0.0)

    public init(type: WinterGramBadgeAnimationType, duration: Double, loop: Bool, directionClockwise: Bool, amplitude: Double) {
        self.type = type
        self.duration = duration
        self.loop = loop
        self.directionClockwise = directionClockwise
        self.amplitude = amplitude
    }

    private enum CodingKeys: String, CodingKey {
        case type, duration, loop, direction, amplitude
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = WinterGramBadgeAnimationType(parsing: try container.decodeIfPresent(String.self, forKey: .type))
        self.duration = (try container.decodeIfPresent(Double.self, forKey: .duration)) ?? 1.0
        self.loop = (try container.decodeIfPresent(Bool.self, forKey: .loop)) ?? true
        let direction = (try container.decodeIfPresent(String.self, forKey: .direction))?.lowercased()
        self.directionClockwise = (direction != "ccw")
        self.amplitude = (try container.decodeIfPresent(Double.self, forKey: .amplitude)) ?? 0.1
    }
}

public struct WinterGramBadgeLayer: Equatable, Decodable {
    public let name: String
    public let source: String
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public let tint: WinterGramBadgeTint
    public let animation: WinterGramBadgeAnimation

    public var isLottie: Bool {
        let lowered = self.source.lowercased()
        return lowered.hasSuffix(".tgs") || lowered.hasSuffix(".json")
    }

    public init(name: String, source: String, x: Double, y: Double, width: Double, height: Double, tint: WinterGramBadgeTint, animation: WinterGramBadgeAnimation) {
        self.name = name
        self.source = source
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.tint = tint
        self.animation = animation
    }

    private enum CodingKeys: String, CodingKey {
        case name, source, x, y, width, height, tint, animation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = (try container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        self.source = (try container.decodeIfPresent(String.self, forKey: .source)) ?? ""
        self.x = (try container.decodeIfPresent(Double.self, forKey: .x)) ?? 0.0
        self.y = (try container.decodeIfPresent(Double.self, forKey: .y)) ?? 0.0
        self.width = (try container.decodeIfPresent(Double.self, forKey: .width)) ?? 0.0
        self.height = (try container.decodeIfPresent(Double.self, forKey: .height)) ?? 0.0
        self.tint = WinterGramBadgeTint(parsing: try container.decodeIfPresent(String.self, forKey: .tint))
        self.animation = (try container.decodeIfPresent(WinterGramBadgeAnimation.self, forKey: .animation)) ?? .none
    }
}

public struct WinterGramBadgePeers: Equatable, Decodable {
    public let users: [Int64]
    public let channels: [Int64]

    public init(users: [Int64], channels: [Int64]) {
        self.users = users
        self.channels = channels
    }

    private enum CodingKeys: String, CodingKey {
        case users, channels
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.users = (try container.decodeIfPresent([Int64].self, forKey: .users)) ?? []
        self.channels = (try container.decodeIfPresent([Int64].self, forKey: .channels)) ?? []
    }
}

public struct WinterGramBadgeDef: Equatable, Decodable {
    public let id: String
    public let peers: WinterGramBadgePeers
    public let priority: Int
    public let layers: [WinterGramBadgeLayer]
    public let description: String

    public init(id: String, peers: WinterGramBadgePeers, priority: Int, layers: [WinterGramBadgeLayer], description: String) {
        self.id = id
        self.peers = peers
        self.priority = priority
        self.layers = layers
        self.description = description
    }

    private enum CodingKeys: String, CodingKey {
        case id, peers, priority, layers, description
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try container.decodeIfPresent(String.self, forKey: .id)) ?? ""
        self.peers = (try container.decodeIfPresent(WinterGramBadgePeers.self, forKey: .peers)) ?? WinterGramBadgePeers(users: [], channels: [])
        self.priority = (try container.decodeIfPresent(Int.self, forKey: .priority)) ?? 0
        let rawLayers = (try container.decodeIfPresent([WinterGramBadgeLayer].self, forKey: .layers)) ?? []
        self.layers = Array(rawLayers.prefix(WinterGramBadgeLimits.maxLayers))
        self.description = (try container.decodeIfPresent(String.self, forKey: .description)) ?? ""
    }
}

public struct WinterGramBadgeManifest: Equatable, Decodable {
    public let version: Int
    public let canvas: Double
    public let badges: [WinterGramBadgeDef]

    public init(version: Int, canvas: Double, badges: [WinterGramBadgeDef]) {
        self.version = version
        self.canvas = canvas
        self.badges = badges
    }

    private enum CodingKeys: String, CodingKey {
        case version, canvas, badges
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = (try container.decodeIfPresent(Int.self, forKey: .version)) ?? 0
        self.canvas = (try container.decodeIfPresent(Double.self, forKey: .canvas)) ?? 1024.0
        let rawBadges = (try container.decodeIfPresent([WinterGramBadgeDef].self, forKey: .badges)) ?? []
        self.badges = Array(rawBadges.prefix(WinterGramBadgeLimits.maxBadges))
    }

    public static let empty = WinterGramBadgeManifest(version: 0, canvas: 1024.0, badges: [])

    public static func decode(from data: Data) -> WinterGramBadgeManifest? {
        return try? JSONDecoder().decode(WinterGramBadgeManifest.self, from: data)
    }

    public var assetSources: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for badge in self.badges {
            for layer in badge.layers where !layer.source.isEmpty {
                if seen.insert(layer.source).inserted {
                    result.append(layer.source)
                }
            }
        }
        return result
    }
}
