import Foundation

// MARK: - Moderation Service
final class ModerationService: Sendable {
    static let shared = ModerationService()

    private let crisisKeywords = [
        "suicide",
        "self-harm",
        "self harm",
        "kill myself",
        "end it all",
        "want to die",
        "abuse",
        "hitting",
        "hurt",
        "unsafe",
        "harm myself",
        "cut myself",
        "cutting"
    ]

    private init() {}

    // MARK: - Crisis Detection
    func checkForCrisis(_ text: String) -> Bool {
        let lowercase = text.lowercased()
        return crisisKeywords.contains { lowercase.contains($0) }
    }

    func getCrisisResources() -> String {
        """
        If you or your child are in immediate danger, please call:

        • 911 (Emergency)
        • 988 (Suicide & Crisis Lifeline)
        • 1-800-4-A-CHILD (Child Abuse Hotline)

        You can also text HOME to 741741 (Crisis Text Line)

        These resources are available 24/7 and provide confidential support.
        """
    }

    func getCrisisMessage(withResources: Bool = true) -> String {
        let baseConcern = "I'm concerned about what you've shared."

        if withResources {
            return "\(baseConcern)\n\n\(getCrisisResources())\n\nWould you like to talk about what's happening?"
        } else {
            return "\(baseConcern) Would you like to talk about what's happening?"
        }
    }
}
