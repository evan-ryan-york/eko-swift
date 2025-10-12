import Foundation
import EkoCore

// MARK: - Lyra ViewModel
@MainActor
@Observable
final class LyraViewModel {
    // MARK: - Text Chat State
    var messages: [Message] = []
    var isLoading = false
    var error: Error?

    // MARK: - Voice State
    var isVoiceMode = false
    private let voiceService = RealtimeVoiceService()

    var voiceStatus: RealtimeVoiceService.Status {
        voiceService.status
    }

    var userTranscript: String {
        voiceService.userTranscript
    }

    var aiTranscript: String {
        voiceService.aiTranscript
    }

    // MARK: - Conversation State
    var conversationId: UUID?
    let childId: UUID

    // MARK: - Services
    private let supabase = SupabaseService.shared
    private let moderation = ModerationService.shared

    // MARK: - Initialization
    init(childId: UUID) {
        self.childId = childId
    }

    // MARK: - Conversation Management
    func loadActiveConversation() async {
        do {
            if let conversation = try await supabase.getActiveConversation(childId: childId) {
                conversationId = conversation.id
                messages = try await supabase.getMessages(conversationId: conversation.id)
            }
        } catch {
            self.error = error
            print("Error loading active conversation: \(error)")
        }
    }

    // MARK: - Text Chat
    func sendMessage(_ text: String) async throws {
        // Check for crisis content
        if moderation.checkForCrisis(text) {
            let crisisMessage = Message(
                id: UUID(),
                role: .system,
                content: moderation.getCrisisMessage(withResources: true),
                timestamp: Date()
            )
            messages.append(crisisMessage)

            // TODO: Log crisis event to backend if needed
            return
        }

        // Add user message to UI immediately
        let userMessage = Message(
            id: UUID(),
            conversationId: conversationId,
            role: .user,
            content: text,
            timestamp: Date()
        )
        messages.append(userMessage)

        // Create conversation if needed
        if conversationId == nil {
            let conversation = try await supabase.createConversation(childId: childId)
            conversationId = conversation.id
        }

        guard let conversationId else {
            throw NetworkError.unknown(NSError(domain: "No conversation ID", code: -1))
        }

        isLoading = true

        // Create placeholder for assistant response
        var assistantMessage = Message(
            id: UUID(),
            conversationId: conversationId,
            role: .assistant,
            content: "",
            timestamp: Date()
        )
        messages.append(assistantMessage)

        do {
            // Stream AI response
            let stream = try await supabase.sendMessage(
                conversationId: conversationId,
                message: text,
                childId: childId
            )

            for try await chunk in stream {
                assistantMessage.content += chunk

                // Update the message in the array
                if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                    messages[index] = assistantMessage
                }
            }

            isLoading = false
        } catch {
            isLoading = false
            self.error = error

            // Remove the empty assistant message on error
            messages.removeAll { $0.id == assistantMessage.id }
            throw error
        }
    }

    // MARK: - Voice Mode
    func startVoiceMode() async {
        do {
            isVoiceMode = true

            // Create conversation if needed
            if conversationId == nil {
                let conversation = try await supabase.createConversation(childId: childId)
                conversationId = conversation.id
            }

            guard let conversationId else {
                throw NetworkError.unknown(NSError(domain: "No conversation ID", code: -1))
            }

            try await voiceService.startSession(
                conversationId: conversationId,
                childId: childId
            )
        } catch {
            self.error = error
            isVoiceMode = false
            print("Error starting voice mode: \(error)")
        }
    }

    func endVoiceMode() {
        voiceService.endSession()
        isVoiceMode = false

        // Add voice transcripts to text chat
        if !voiceService.userTranscript.isEmpty {
            messages.append(Message(
                id: UUID(),
                conversationId: conversationId,
                role: .user,
                content: voiceService.userTranscript,
                timestamp: Date()
            ))
        }

        if !voiceService.aiTranscript.isEmpty {
            messages.append(Message(
                id: UUID(),
                conversationId: conversationId,
                role: .assistant,
                content: voiceService.aiTranscript,
                timestamp: Date()
            ))
        }
    }

    func interruptAI() {
        voiceService.interrupt()
    }

    // MARK: - Conversation Completion
    func completeConversation() async throws {
        guard let conversationId else { return }

        let result = try await supabase.completeConversation(conversationId: conversationId)

        // Reset state
        self.conversationId = nil
        self.messages = []

        print("Conversation completed with title: \(result.title)")
    }
}
