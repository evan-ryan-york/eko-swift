import Foundation

// MARK: - Child Model
public struct Child: Codable, Identifiable, Sendable {
    public let id: UUID
    public let userId: UUID
    public var name: String
    public var age: Int
    public var temperament: Temperament
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        userId: UUID,
        name: String,
        age: Int,
        temperament: Temperament,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.age = age
        self.temperament = temperament
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case age
        case temperament
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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
