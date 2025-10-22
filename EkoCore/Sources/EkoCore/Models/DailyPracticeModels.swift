// Daily Practice Models
// Data models for the Daily Practice feature

import Foundation

// MARK: - Activity

/// Represents a daily practice activity
public struct DailyPracticeActivity: Codable, Identifiable, Sendable {
    // System fields
    public let id: UUID
    public let createdAt: Date?
    public let updatedAt: Date?

    // Core identifiers
    public let dayNumber: Int
    public let ageBand: String
    public let moduleName: String
    public let moduleDisplayName: String

    // Activity metadata
    public let title: String
    public let description: String?
    public let skillFocus: String
    public let category: String?
    public let activityType: String
    public let isReflection: Bool

    // Scenario content
    public let scenario: String

    // Research and learning (all optional)
    public let researchConcept: String?
    public let researchKeyInsight: String?
    public let researchCitation: String?
    public let researchAdditionalContext: String?

    // Additional content
    public let bestApproach: String?
    public let followUpQuestions: [String]?

    // Related data (fetched from separate tables)
    public let prompts: [DailyPracticePrompt]
    public let actionableTakeaway: ActionableTakeaway

    public init(
        id: UUID,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        dayNumber: Int,
        ageBand: String,
        moduleName: String,
        moduleDisplayName: String,
        title: String,
        description: String? = nil,
        skillFocus: String,
        category: String? = nil,
        activityType: String = "basic-scenario",
        isReflection: Bool = false,
        scenario: String,
        researchConcept: String? = nil,
        researchKeyInsight: String? = nil,
        researchCitation: String? = nil,
        researchAdditionalContext: String? = nil,
        bestApproach: String? = nil,
        followUpQuestions: [String]? = nil,
        prompts: [DailyPracticePrompt],
        actionableTakeaway: ActionableTakeaway
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dayNumber = dayNumber
        self.ageBand = ageBand
        self.moduleName = moduleName
        self.moduleDisplayName = moduleDisplayName
        self.title = title
        self.description = description
        self.skillFocus = skillFocus
        self.category = category
        self.activityType = activityType
        self.isReflection = isReflection
        self.scenario = scenario
        self.researchConcept = researchConcept
        self.researchKeyInsight = researchKeyInsight
        self.researchCitation = researchCitation
        self.researchAdditionalContext = researchAdditionalContext
        self.bestApproach = bestApproach
        self.followUpQuestions = followUpQuestions
        self.prompts = prompts
        self.actionableTakeaway = actionableTakeaway
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, category, scenario, prompts
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case dayNumber = "day_number"
        case ageBand = "age_band"
        case moduleName = "module_name"
        case moduleDisplayName = "module_display_name"
        case skillFocus = "skill_focus"
        case activityType = "activity_type"
        case isReflection = "is_reflection"
        case researchConcept = "research_concept"
        case researchKeyInsight = "research_key_insight"
        case researchCitation = "research_citation"
        case researchAdditionalContext = "research_additional_context"
        case bestApproach = "best_approach"
        case followUpQuestions = "follow_up_questions"
        case actionableTakeaway = "actionable_takeaway"
    }
}

// MARK: - Prompt

/// Represents a prompt within a daily practice activity
public struct DailyPracticePrompt: Codable, Identifiable, Sendable {
    public let promptId: String
    public let type: PromptType
    public let promptText: String
    public let order: Int
    public let points: Int
    public let branchLogic: BranchLogic?
    public let options: [PromptOption]
    public let config: PromptConfig?

    public var id: String { promptId }

    public init(
        promptId: String,
        type: PromptType,
        promptText: String,
        order: Int,
        points: Int,
        branchLogic: BranchLogic? = nil,
        options: [PromptOption],
        config: PromptConfig? = nil
    ) {
        self.promptId = promptId
        self.type = type
        self.promptText = promptText
        self.order = order
        self.points = points
        self.branchLogic = branchLogic
        self.options = options
        self.config = config
    }

    enum CodingKeys: String, CodingKey {
        case promptId, type, order, points, options, config
        case promptText = "promptText"
        case branchLogic = "branchLogic"
    }
}

// MARK: - Prompt Type

/// Types of interaction patterns for prompts
public enum PromptType: String, Codable, Sendable {
    case stateIdentification = "state-identification"
    case bestResponse = "best-response"
    case sequentialChoice = "sequential-choice"
    case spotMistake = "spot-mistake"
    case dialogueCompletion = "dialogue-completion"
    case beforeAfterComparison = "before-after-comparison"
    case whatHappensNext = "what-happens-next"
    case sequencing = "sequencing"
    case selectAll = "select-all"
    case rating = "rating"
    case matching = "matching"
    case textInput = "text-input"
    case reflection = "reflection"
}

// MARK: - Branch Logic

/// Conditional logic for branching to different prompts based on user selection
public struct BranchLogic: Codable, Sendable {
    public let condition: BranchCondition
    public let nextPrompt: String

    public init(condition: BranchCondition, nextPrompt: String) {
        self.condition = condition
        self.nextPrompt = nextPrompt
    }
}

/// Condition for branch logic
public struct BranchCondition: Codable, Sendable {
    public let ifSelected: String
    public let `operator`: String

    public init(ifSelected: String, operator: String) {
        self.ifSelected = ifSelected
        self.operator = `operator`
    }
}

// MARK: - Prompt Option

/// A selectable option within a prompt
public struct PromptOption: Codable, Identifiable, Sendable {
    public let optionId: String
    public let optionText: String
    public let correct: Bool
    public let points: Int
    public let feedback: String
    public let metadata: OptionMetadata?
    public let scienceNote: ScienceNote?

    public var id: String { optionId }

    public init(
        optionId: String,
        optionText: String,
        correct: Bool,
        points: Int,
        feedback: String,
        metadata: OptionMetadata? = nil,
        scienceNote: ScienceNote? = nil
    ) {
        self.optionId = optionId
        self.optionText = optionText
        self.correct = correct
        self.points = points
        self.feedback = feedback
        self.metadata = metadata
        self.scienceNote = scienceNote
    }

    enum CodingKeys: String, CodingKey {
        case optionId, correct, points, feedback, metadata
        case optionText = "optionText"
        case scienceNote = "scienceNote"
    }
}

// MARK: - Option Metadata

/// Additional metadata for options (used for specific prompt types)
public struct OptionMetadata: Codable, Sendable {
    public let version: String?
    public let matchTarget: String?
    public let correctOrder: Int?

    public init(version: String? = nil, matchTarget: String? = nil, correctOrder: Int? = nil) {
        self.version = version
        self.matchTarget = matchTarget
        self.correctOrder = correctOrder
    }
}

// MARK: - Science Note

/// Research-backed explanation embedded in feedback
public struct ScienceNote: Codable, Sendable {
    public let brief: String
    public let citation: String?
    public let showCitation: Bool

    public init(brief: String, citation: String? = nil, showCitation: Bool = false) {
        self.brief = brief
        self.citation = citation
        self.showCitation = showCitation
    }
}

// MARK: - Prompt Config

/// Configuration for specific prompt interaction patterns
public struct PromptConfig: Codable, Sendable {
    public let allowMultiple: Bool?
    public let minCorrect: Int?
    public let scaleType: String?
    public let scaleRange: [Int]?
    public let inputType: String?
    public let wordBank: [String]?
    public let sequenceType: String?

    public init(
        allowMultiple: Bool? = nil,
        minCorrect: Int? = nil,
        scaleType: String? = nil,
        scaleRange: [Int]? = nil,
        inputType: String? = nil,
        wordBank: [String]? = nil,
        sequenceType: String? = nil
    ) {
        self.allowMultiple = allowMultiple
        self.minCorrect = minCorrect
        self.scaleType = scaleType
        self.scaleRange = scaleRange
        self.inputType = inputType
        self.wordBank = wordBank
        self.sequenceType = sequenceType
    }
}

// MARK: - Actionable Takeaway

/// The concrete tool/strategy that users learn from the activity
public struct ActionableTakeaway: Codable, Sendable {
    public let toolName: String
    public let toolType: String?
    public let whenToUse: String
    public let howTo: [String]
    public let whyItWorks: String
    public let tryItWhen: String?
    public let example: TakeawayExample

    public init(
        toolName: String,
        toolType: String? = nil,
        whenToUse: String,
        howTo: [String],
        whyItWorks: String,
        tryItWhen: String? = nil,
        example: TakeawayExample
    ) {
        self.toolName = toolName
        self.toolType = toolType
        self.whenToUse = whenToUse
        self.howTo = howTo
        self.whyItWorks = whyItWorks
        self.tryItWhen = tryItWhen
        self.example = example
    }

    enum CodingKeys: String, CodingKey {
        case toolName, toolType, whenToUse, howTo, whyItWorks, tryItWhen, example
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try camelCase first (database structure format), fallback to snake_case
        self.toolName = try container.decode(String.self, forKey: .toolName)
        self.toolType = try? container.decode(String.self, forKey: .toolType)
        self.whenToUse = try container.decode(String.self, forKey: .whenToUse)
        self.howTo = try container.decode([String].self, forKey: .howTo)
        self.whyItWorks = try container.decode(String.self, forKey: .whyItWorks)
        self.tryItWhen = try? container.decode(String.self, forKey: .tryItWhen)
        self.example = try container.decode(TakeawayExample.self, forKey: .example)
    }
}

// MARK: - Takeaway Example

/// Real-world example of using the tool
public struct TakeawayExample: Codable, Sendable {
    public let situation: String
    public let action: String
    public let outcome: String

    public init(situation: String, action: String, outcome: String) {
        self.situation = situation
        self.action = action
        self.outcome = outcome
    }
}

// MARK: - Response Models

/// Response from get-daily-activity Edge Function
public struct GetDailyActivityResponse: Codable, Sendable {
    public let dayNumber: Int?
    public let activity: DailyPracticeActivity?
    public let userProgress: UserProgress?
    public let error: String?
    public let message: String?
    public let lastCompleted: Int?
    public let completedAt: String?

    public init(
        dayNumber: Int? = nil,
        activity: DailyPracticeActivity? = nil,
        userProgress: UserProgress? = nil,
        error: String? = nil,
        message: String? = nil,
        lastCompleted: Int? = nil,
        completedAt: String? = nil
    ) {
        self.dayNumber = dayNumber
        self.activity = activity
        self.userProgress = userProgress
        self.error = error
        self.message = message
        self.lastCompleted = lastCompleted
        self.completedAt = completedAt
    }

    enum CodingKeys: String, CodingKey {
        case activity, error, message
        case dayNumber = "day_number"
        case userProgress = "user_progress"
        case lastCompleted = "last_completed"
        case completedAt = "completed_at"
    }
}

/// User progress information
public struct UserProgress: Codable, Sendable {
    public let lastCompleted: Int
    public let currentDay: Int

    public init(lastCompleted: Int, currentDay: Int) {
        self.lastCompleted = lastCompleted
        self.currentDay = currentDay
    }

    enum CodingKeys: String, CodingKey {
        case lastCompleted = "last_completed"
        case currentDay = "current_day"
    }
}

/// Response from complete-activity Edge Function
public struct CompleteActivityResponse: Codable, Sendable {
    public let success: Bool
    public let completedDay: Int?
    public let message: String?
    public let error: String?

    public init(success: Bool, completedDay: Int? = nil, message: String? = nil, error: String? = nil) {
        self.success = success
        self.completedDay = completedDay
        self.message = message
        self.error = error
    }

    enum CodingKeys: String, CodingKey {
        case success, message, error
        case completedDay = "completed_day"
    }
}

/// Response from session-related Edge Functions
public struct SessionResponse: Codable, Sendable {
    public let success: Bool
    public let sessionId: UUID?
    public let message: String?
    public let error: String?

    public init(success: Bool, sessionId: UUID? = nil, message: String? = nil, error: String? = nil) {
        self.success = success
        self.sessionId = sessionId
        self.message = message
        self.error = error
    }

    enum CodingKeys: String, CodingKey {
        case success, message, error
        case sessionId = "session_id"
    }
}

// MARK: - Analytics Models

/// Detailed result for a single prompt (for analytics)
public struct PromptResult: Codable, Sendable {
    public let promptId: String
    public let tries: Int
    public let logs: [AttemptLog]
    public let pointsEarned: Int
    public let completed: Bool

    public init(promptId: String, tries: Int, logs: [AttemptLog], pointsEarned: Int, completed: Bool) {
        self.promptId = promptId
        self.tries = tries
        self.logs = logs
        self.pointsEarned = pointsEarned
        self.completed = completed
    }
}

/// Log entry for a single attempt at a prompt
public struct AttemptLog: Codable, Sendable {
    public let optionId: String
    public let correct: Bool
    public let timestamp: String

    public init(optionId: String, correct: Bool, timestamp: String) {
        self.optionId = optionId
        self.correct = correct
        self.timestamp = timestamp
    }
}
