//
//  SupabaseManager+AIProcessing.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/30/25.
//

// Services/SupabaseManager+AIProcessing.swift (새 파일)

import Foundation
import Supabase

extension SupabaseManager {
    func triggerAIProcessing(
        postId: Int,
        content: String,
        hashtags: [String],
        mood: String?,
        userId: UUID? = nil
    ) async throws {
        struct AIProcessingRequest: Encodable {
            let postId: Int
            let content: String
            let hashtags: [String]
            let mood: String?
            let userId: String?
        }
        
        let request = AIProcessingRequest(
            postId: postId,
            content: content,
            hashtags: hashtags,
            mood: mood,
            userId: userId?.uuidString ?? currentUser?.id.uuidString
        )
        
        print("🤖 AI Processing 트리거: Post \(postId)")
        
        // Edge Function 호출 (에러 무시)
        _ = try? await client.functions.invoke(
            "process-post-ai",
            options: FunctionInvokeOptions(body: request)
        )
    }
}
