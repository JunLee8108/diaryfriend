// Services/SupabaseManager+Chat.swift
import Foundation
import Supabase

// MARK: - Chat Errors
enum ChatError: LocalizedError {
    case invalidResponse
    case networkError(Error)
    case characterNotFound
    case limitReached
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .characterNotFound:
            return "Character not found"
        case .limitReached:
            return "Conversation limit reached"
        }
    }
}

// MARK: - SupabaseManager Extension for Chat
extension SupabaseManager {
    private var currentUserLanguage: String {
        UserProfileStore.shared.userProfile?.language ?? "English"
    }
    
    // MARK: - Chat with AI
    func chatWithAI(
        character: CharacterWithAffinity,
        messages: [ChatMessage]  // ChatModels.swift에서 정의된 타입 사용
    ) async throws -> String {
        
        // personality 처리
        let personality: [String]
        if let personalityArray = character.personality {
            personality = personalityArray
        } else {
            personality = ["friendly", "helpful"]
        }
        
        // Edge Function용 요청 구조체
        struct ChatRequest: Encodable {
            let character: CharacterInfo
            let conversation: [ConversationMessage]
            let language: String
            
            struct CharacterInfo: Encodable {
                let name: String
                let personality: [String]
                let prompt_description: String
            }
            
            struct ConversationMessage: Encodable {
                let role: String
                let content: String
            }
        }
        
        do {
            // Edge Function 호출 - Supabase 2.32 방식
            struct FunctionResponse: Decodable {
                let success: Bool
                let response: String?
            }
            
            // 요청 데이터 구성
            let requestBody = ChatRequest(
                character: ChatRequest.CharacterInfo(
                    name: character.name,
                    personality: personality,
                    prompt_description: character.prompt_description ?? ""
                ),
                conversation: messages.map { message in
                    ChatRequest.ConversationMessage(
                        role: message.sender.rawValue,
                        content: message.content
                    )
                },
                language: currentUserLanguage
            )
            
            let response: FunctionResponse = try await client.functions
                .invoke(
                    "chat-with-ai",
                    options: FunctionInvokeOptions(body: requestBody)
                )
            
            // 응답 확인
            if response.success, let aiResponse = response.response {
                return aiResponse
            }
            
            throw ChatError.invalidResponse
            
        } catch {
            print("❌ Chat AI error: \(error)")
            throw ChatError.networkError(error)
        }
    }
    
    // MARK: - Generate Initial Greeting
    func generateInitialGreeting(for character: CharacterWithAffinity) -> String {
        // greeting_messages가 있으면 사용
        if let greetingMessages = character.greeting_messages {
            let language = currentUserLanguage
            let greetings: [String]
            if language == "Korean" {
                greetings = greetingMessages.Korean ?? greetingMessages.English ?? []
            } else {
                greetings = greetingMessages.English ?? greetingMessages.Korean ?? []
            }
            
            if !greetings.isEmpty {
                let template = greetings.randomElement() ?? greetings[0]
                // ${name} placeholder 치환
                let displayName = language == "Korean" && character.korean_name != nil ?
                character.korean_name! : character.name
                return template.replacingOccurrences(of: "${name}", with: displayName)
            }
        }
        
        // Fallback greetings
        let fallbackGreetings = [
            "Hi! I'm \(character.name). How was your day?",
            "\(character.name) here! Want to tell me about your day?",
            "Nice to meet you! I'm \(character.name). How are you feeling today?"
        ]
        
        return fallbackGreetings.randomElement() ?? fallbackGreetings[0]
    }
}
