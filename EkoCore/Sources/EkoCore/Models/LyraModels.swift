import Foundation

// MARK: - Lyra Child Context
public struct LyraChildContext: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let age: Int
    public let temperament: Temperament
    public let talkative: Int
    public let sensitivity: Int
    public let accountability: Int
    public let recentThemes: [String]
    public let effectiveStrategies: [String]

    public init(
        id: UUID,
        name: String,
        age: Int,
        temperament: Temperament,
        talkative: Int,
        sensitivity: Int,
        accountability: Int,
        recentThemes: [String],
        effectiveStrategies: [String]
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.temperament = temperament
        self.talkative = talkative
        self.sensitivity = sensitivity
        self.accountability = accountability
        self.recentThemes = recentThemes
        self.effectiveStrategies = effectiveStrategies
    }
}

// MARK: - Create Conversation DTO
public struct CreateConversationDTO: Codable, Sendable {
    public let childId: UUID

    public init(childId: UUID) {
        self.childId = childId
    }

    enum CodingKeys: String, CodingKey {
        case childId = "childId"
    }
}

// MARK: - Send Message DTO
public struct SendMessageDTO: Codable, Sendable {
    public let conversationId: UUID
    public let message: String
    public let childId: UUID

    public init(
        conversationId: UUID,
        message: String,
        childId: UUID
    ) {
        self.conversationId = conversationId
        self.message = message
        self.childId = childId
    }

    enum CodingKeys: String, CodingKey {
        case conversationId
        case message
        case childId
    }
}

// MARK: - Complete Conversation DTO
public struct CompleteConversationDTO: Codable, Sendable {
    public let conversationId: UUID

    public init(conversationId: UUID) {
        self.conversationId = conversationId
    }

    enum CodingKeys: String, CodingKey {
        case conversationId
    }
}

// MARK: - Complete Conversation Response
public struct CompleteConversationResponse: Codable, Sendable {
    public let success: Bool
    public let title: String
    public let insights: ConversationInsights?

    public init(
        success: Bool,
        title: String,
        insights: ConversationInsights?
    ) {
        self.success = success
        self.title = title
        self.insights = insights
    }
}

// MARK: - Conversation Insights
public struct ConversationInsights: Codable, Sendable {
    public let behavioralThemes: [[String: String]]?
    public let communicationStrategies: [[String: String]]?
    public let significantEvents: [[String: String]]?

    public init(
        behavioralThemes: [[String: String]]?,
        communicationStrategies: [[String: String]]?,
        significantEvents: [[String: String]]?
    ) {
        self.behavioralThemes = behavioralThemes
        self.communicationStrategies = communicationStrategies
        self.significantEvents = significantEvents
    }

    enum CodingKeys: String, CodingKey {
        case behavioralThemes = "behavioral_themes"
        case communicationStrategies = "communication_strategies"
        case significantEvents = "significant_events"
    }
}

// MARK: - Create Realtime Session DTO
public struct CreateRealtimeSessionDTO: Codable, Sendable {
    public let sdp: String
    public let conversationId: UUID
    public let childId: UUID

    public init(
        sdp: String,
        conversationId: UUID,
        childId: UUID
    ) {
        self.sdp = sdp
        self.conversationId = conversationId
        self.childId = childId
    }

    enum CodingKeys: String, CodingKey {
        case sdp
        case conversationId
        case childId
    }
}

// MARK: - Realtime Session Response
public struct RealtimeSessionResponse: Codable, Sendable {
    public let sdp: String
    public let callId: String?

    public init(
        sdp: String,
        callId: String?
    ) {
        self.sdp = sdp
        self.callId = callId
    }

    enum CodingKeys: String, CodingKey {
        case sdp
        case callId
    }
}
