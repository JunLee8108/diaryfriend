//
//  SupabaseManager+Diary.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/30/25.
//

// Services/SupabaseManager+Diary.swift
import Foundation
import Supabase

extension SupabaseManager {
    private var currentUserLanguage: String {
        UserProfileStore.shared.userProfile?.language ?? "English"
    }
    
    func generateDiaryFromChat(
        character: CharacterWithAffinity,
        messages: [ChatMessage],
    ) async throws -> GeneratedDiaryData {
        
        let personality = character.personality ?? ["friendly", "helpful"]
        
        struct DiaryRequest: Encodable {
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
        
        struct DiaryResponse: Decodable {
            let success: Bool
            let diary: String?
            let mood: String?
            let mood_confidence: Double?
            let hashtags: [String]?
        }
        
        let requestBody = DiaryRequest(
            character: DiaryRequest.CharacterInfo(
                name: character.name,
                personality: personality,
                prompt_description: character.prompt_description ?? ""
            ),
            conversation: messages.map { message in
                DiaryRequest.ConversationMessage(
                    role: message.sender == .user ? "user" : "assistant",
                    content: message.content
                )
            },
            language: currentUserLanguage
        )
        
        let response: DiaryResponse = try await client.functions.invoke(
            "generate-diary-from-chat",
            options: FunctionInvokeOptions(body: requestBody)
        )
        
        guard response.success,
              let diary = response.diary,
              let mood = response.mood else {
            throw ChatError.invalidResponse
        }
        
        return GeneratedDiaryData(
            content: diary,
            mood: mood,
            hashtags: response.hashtags ?? []
        )
    }
}
