import Foundation

// MARK: - Child Model
public struct Child: Codable, Identifiable, Sendable {
    public let id: UUID
    public let userId: UUID
    public var name: String
    public var age: Int
    public var birthday: Date
    public var goals: [String]
    public var topics: [String]
    public var temperament: Temperament
    public var temperamentTalkative: Int
    public var temperamentSensitivity: Int
    public var temperamentAccountability: Int
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        userId: UUID,
        name: String,
        age: Int,
        birthday: Date,
        goals: [String] = [],
        topics: [String] = [],
        temperament: Temperament,
        temperamentTalkative: Int = 5,
        temperamentSensitivity: Int = 5,
        temperamentAccountability: Int = 5,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.age = age
        self.birthday = birthday
        self.goals = goals
        self.topics = topics
        self.temperament = temperament
        self.temperamentTalkative = temperamentTalkative
        self.temperamentSensitivity = temperamentSensitivity
        self.temperamentAccountability = temperamentAccountability
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case age
        case birthday
        case goals
        case topics
        case temperament
        case temperamentTalkative = "temperament_talkative"
        case temperamentSensitivity = "temperament_sensitivity"
        case temperamentAccountability = "temperament_accountability"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Lyra Context
    public func lyraContext(
        recentThemes: [String] = [],
        effectiveStrategies: [String] = []
    ) -> LyraChildContext {
        LyraChildContext(
            id: id,
            name: name,
            age: age,
            temperament: temperament,
            talkative: temperamentTalkative,
            sensitivity: temperamentSensitivity,
            accountability: temperamentAccountability,
            recentThemes: recentThemes,
            effectiveStrategies: effectiveStrategies
        )
    }
}

// MARK: - Temperament
public enum Temperament: String, Codable, Sendable, CaseIterable {
    case easygoing
    case sensitive
    case spirited
    case cautious

    public var displayName: String {
        switch self {
        case .easygoing: return "Easygoing"
        case .sensitive: return "Sensitive"
        case .spirited: return "Spirited"
        case .cautious: return "Cautious"
        }
    }

    public var description: String {
        switch self {
        case .easygoing:
            return "Adaptable, generally positive, quick to establish routines"
        case .sensitive:
            return "Emotionally perceptive, may be easily overwhelmed"
        case .spirited:
            return "High energy, strong-willed, intense reactions"
        case .cautious:
            return "Observant, slow to warm up, careful in new situations"
        }
    }
}
