//
//  Services/ChatService.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/29/25.
//

import Foundation
import Supabase

// MARK: - Models
struct DailyPermission: Codable {
    let canChat: Bool
    let reason: String?
    let postCount: Int
    let deletedCount: Int
    
    enum CodingKeys: String, CodingKey {
        case canChat = "can_chat"
        case reason
        case postCount = "post_count"
        case deletedCount = "deleted_count"
    }
}

struct SessionInfo: Codable {
    let sessionId: UUID
    let isNew: Bool
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case isNew = "is_new"
        case isActive = "is_active"
    }
}

struct ChatSession {
    let id: UUID
    let characterId: Int
    let date: Date
    let messageCount: Int
    let isActive: Bool
    let postId: Int?
}

// Private model for DB responses
private struct ChatSessionData: Codable {
    let id: UUID
    let characterId: Int
    let sessionDate: String  // Fixed: date → sessionDate
    let messageCount: Int
    let isActive: Bool
    let postId: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case characterId = "character_id"
        case sessionDate = "session_date"  // Fixed: matching DB column name
        case messageCount = "message_count"
        case isActive = "is_active"
        case postId = "post_id"
    }
}

// MARK: - Errors
enum ChatServiceError: LocalizedError {
    case permissionDenied(String)
    case sessionNotFound
    case messageLimitReached
    case networkError(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied(let reason):
            return reason
        case .sessionNotFound:
            return "Chat session not found"
        case .messageLimitReached:
            return "Message limit reached (10 messages)"
        case .networkError(let error):
            return "Network error: \(error)"
        case .invalidResponse:
            return "Invalid server response"
        }
    }
}

// MARK: - ChatService
@MainActor
class ChatService: ObservableObject {
    static let shared = ChatService()
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Memory Cache
    private var sessionCache: [String: UUID] = [:]  // "characterId_date" : sessionId
    private var messageCache: [UUID: [ChatMessage]] = [:]  // sessionId : messages
    private var permissionCache: [String: DailyPermission] = [:]  // "date" : permission
    private var sessionInfoCache: [UUID: ChatSession] = [:]  // sessionId : session info
    private var dateSessionsCache: [String: Set<Int>] = [:]
    private var noSessionCache: Set<String> = []  // "characterId_date" where no session exists
    private var generatedDiaryDataCache: [UUID: GeneratedDiaryData] = [:]
    
    // MARK: - Published States
    @Published var isLoading = false
    @Published var currentSessionId: UUID?
    @Published var currentMessages: [ChatMessage] = []
    @Published var currentMessageCount = 0
    
    private init() {}
    
    // MARK: - Permission Check
    func checkDailyPermission(date: Date) async throws -> DailyPermission {
        let dateString = formatDate(date)
        
        // Check cache first
        if let cached = permissionCache[dateString] {
            print("💾 Using cached permission for \(dateString)")
            return cached
        }
        
        print("🔍 Checking permission for date: \(dateString)")
        
        do {
            let response = try await supabase.rpc(
                "check_daily_permission",
                params: ["p_date": dateString]
            ).execute()
            
            let permission = try JSONDecoder().decode(DailyPermission.self, from: response.data)
            
            // Cache the result
            permissionCache[dateString] = permission
            
            print("✅ Permission check result: canChat=\(permission.canChat), reason=\(permission.reason ?? "none")")
            return permission
            
        } catch {
            print("❌ Permission check failed: \(error)")
            throw ChatServiceError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Session Check (생성하지 않음)
    func checkExistingSession(characterId: Int, date: Date) async throws -> SessionInfo? {
        let dateString = formatDate(date)
        let cacheKey = "\(characterId)_\(dateString)"
        
        guard let userId = UserProfileStore.shared.userProfile?.id else {
            throw ChatServiceError.networkError("User profile not loaded")
        }
        
        // Check "no session" cache first
        if noSessionCache.contains(cacheKey) {
            print("💾 Cached: No session exists for \(cacheKey)")
            return nil
        }
        
        // Check existing session cache
        if let cachedId = sessionCache[cacheKey],
           let cachedInfo = sessionInfoCache[cachedId] {
            print("💾 Using cached session: \(cachedId)")
            return SessionInfo(
                sessionId: cachedId,
                isNew: false,
                isActive: cachedInfo.isActive
            )
        }
        
        print("🔍 Checking for existing session (no creation)")
        
        do {
            // Query all matching sessions (should be 0 or 1)
            let response = try await supabase
                .from("chat_sessions")
                .select("*")
                .eq("character_id", value: characterId)
                .eq("session_date", value: dateString)  // Fixed: using session_date
                .eq("user_id", value: userId.uuidString) 
                .execute()
            
            // Check if data is empty
            let sessions = try JSONDecoder().decode([ChatSessionData].self, from: response.data)
            
            guard let session = sessions.first else {
                print("ℹ️ No existing session found - caching this state")
                noSessionCache.insert(cacheKey)  // Cache "no session" state
                return nil
            }
            
            // Update cache
            sessionCache[cacheKey] = session.id
            sessionInfoCache[session.id] = ChatSession(
                id: session.id,
                characterId: characterId,
                date: date,
                messageCount: session.messageCount,
                isActive: session.isActive,
                postId: session.postId
            )
            
            return SessionInfo(
                sessionId: session.id,
                isNew: false,
                isActive: session.isActive
            )
            
        } catch {
            print("⚠️ Session check error: \(error)")
            return nil
        }
    }
    
    // MARK: - Session Creation
    func createSession(characterId: Int, date: Date) async throws -> SessionInfo {
        let dateString = formatDate(date)
        let cacheKey = "\(characterId)_\(dateString)"
        
        // UserProfileStore를 source of truth로 사용
        guard let userId = UserProfileStore.shared.userProfile?.id else {
            throw ChatServiceError.networkError("User profile not loaded")
        }
        
        print("🆕 Creating new session for character \(characterId) on \(dateString) for user \(userId)")
        
        do {
            let sessionId = UUID()
            
            // Create session in DB with user_id
            try await supabase
                .from("chat_sessions")
                .insert([
                    "id": AnyJSON(sessionId.uuidString),
                    "character_id": AnyJSON(characterId),
                    "session_date": AnyJSON(dateString),
                    "message_count": AnyJSON(0),
                    "is_active": AnyJSON(true),
                    "user_id": AnyJSON(userId.uuidString)  // ✅ UserProfileStore에서 가져온 user_id
                ])
                .execute()
            
            // Update cache
            sessionCache[cacheKey] = sessionId
            sessionInfoCache[sessionId] = ChatSession(
                id: sessionId,
                characterId: characterId,
                date: date,
                messageCount: 0,
                isActive: true,
                postId: nil
            )
            
            // Remove from "no session" cache since we just created one
            noSessionCache.remove(cacheKey)
            
            if var cachedSet = dateSessionsCache[dateString] {
                cachedSet.insert(characterId)
                dateSessionsCache[dateString] = cachedSet
            } else {
                dateSessionsCache[dateString] = [characterId]
            }
            
            currentSessionId = sessionId
            
            print("✅ Session created: \(sessionId)")
            
            return SessionInfo(
                sessionId: sessionId,
                isNew: true,
                isActive: true
            )
            
        } catch {
            print("❌ Session creation failed: \(error)")
            throw ChatServiceError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Batch Session Check (새 메서드 추가)
    func getCharactersWithSessions(date: Date, characterIds: [Int]) async throws -> Set<Int> {
        let dateString = formatDate(date)
        
        // 캐시 확인
        if let cached = dateSessionsCache[dateString] {
            print("💾 Using cached session characters for \(dateString)")
            return cached
        }
        
        guard let userId = UserProfileStore.shared.userProfile?.id else {
            throw ChatServiceError.networkError("User profile not loaded")
        }
        
        print("🔍 Fetching all sessions for date \(dateString) in single query")
        
        // 단일 쿼리로 해당 날짜의 모든 세션 확인
        let response = try await supabase
            .from("chat_sessions")
            .select("character_id")
            .eq("session_date", value: dateString)
            .eq("user_id", value: userId.uuidString)
            .in("character_id", values: characterIds)
            .execute()
        
        struct SessionCharacter: Codable {
            let characterId: Int
            enum CodingKeys: String, CodingKey {
                case characterId = "character_id"
            }
        }
        
        let sessions = try JSONDecoder().decode([SessionCharacter].self, from: response.data)
        let characterSet = Set(sessions.map { $0.characterId })
        
        // 캐시 저장
        dateSessionsCache[dateString] = characterSet
        
        print("✅ Found sessions for \(characterSet.count) characters")
        return characterSet
    }
    
    // MARK: - Message Management
    func loadMessages(sessionId: UUID) async throws -> [ChatMessage] {
        // Check cache first
        if let cached = messageCache[sessionId] {
            print("💾 Using cached messages: \(cached.count) messages")
            currentMessages = cached
            currentMessageCount = cached.filter { $0.sender == .user }.count
            return cached
        }
        
        print("📥 Loading messages for session: \(sessionId)")
        
        do {
            let response = try await supabase
                .from("chat_messages")
                .select("*")
                .eq("session_id", value: sessionId.uuidString)
                .order("message_order")
                .execute()
            
            let decoder = JSONDecoder()
            
            // Date decoding strategy
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
            }
            
            let messages = try decoder.decode([ChatMessage].self, from: response.data)
            
            // Update cache
            messageCache[sessionId] = messages
            currentMessages = messages
            currentMessageCount = messages.filter { $0.sender == .user }.count
            
            print("✅ Loaded \(messages.count) messages")
            return messages
            
        } catch {
            print("❌ Message loading failed: \(error)")
            return []
        }
    }
    
    func saveMessage(sessionId: UUID, message: ChatMessage) async throws -> Int {
        print("💾 Saving message to session: \(sessionId)")
        
        // Calculate message order based on existing messages
        let existingCount = messageCache[sessionId]?.count ?? 0
        
        // Immediately update memory cache for instant UI feedback
        if messageCache[sessionId] != nil {
            messageCache[sessionId]?.append(message)
        } else {
            messageCache[sessionId] = [message]
        }
        currentMessages.append(message)
        
        do {
            // Save to server with correct message_order
            try await supabase
                .from("chat_messages")
                .insert([
                    "session_id": AnyJSON(sessionId.uuidString),
                    "sender": AnyJSON(message.sender.rawValue),
                    "content": AnyJSON(message.content),
                    "message_order": AnyJSON(existingCount)  // 0-based ordering
                ])
                .execute()
            
            // Increment count for user messages
            if message.sender == .user {
                let response = try await supabase.rpc(
                    "increment_message_count",
                    params: ["p_session_id": sessionId.uuidString]
                ).execute()
                
                let newCount = try JSONDecoder().decode(Int.self, from: response.data)
                currentMessageCount = newCount
                
                // Update session info cache
                if let session = sessionInfoCache[sessionId] {
                    sessionInfoCache[sessionId] = ChatSession(
                        id: session.id,
                        characterId: session.characterId,
                        date: session.date,
                        messageCount: newCount,
                        isActive: session.isActive,
                        postId: session.postId
                    )
                }
                
                print("✅ Message saved. User message count: \(newCount)")
                return newCount
            }
            
            print("✅ AI message saved")
            return currentMessageCount
            
        } catch {
            // Rollback on failure
            messageCache[sessionId]?.removeLast()
            currentMessages.removeLast()
            
            print("❌ Message save failed: \(error)")
            throw ChatServiceError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Post Creation
    func lockDailyAccess(date: Date, postId: Int, sessionId: UUID) async throws {
        let dateString = formatDate(date)
        print("🔒 Locking daily access for \(dateString)")
        
        do {
            try await supabase.rpc(
                "lock_daily_access",
                params: [
                    "p_date": AnyJSON(dateString),
                    "p_post_id": AnyJSON(postId),
                    "p_session_id": AnyJSON(sessionId.uuidString)
                ]
            ).execute()
            
            // Update cache
            permissionCache[dateString] = DailyPermission(
                canChat: false,
                reason: "You’ve already written a diary entry for this date.",
                postCount: 1,
                deletedCount: 0
            )
            
            // Update session info
            if let session = sessionInfoCache[sessionId] {
                sessionInfoCache[sessionId] = ChatSession(
                    id: session.id,
                    characterId: session.characterId,
                    date: session.date,
                    messageCount: session.messageCount,
                    isActive: false,
                    postId: postId
                )
            }
            
            print("✅ Daily access locked")
            
        } catch {
            print("❌ Lock daily access failed: \(error)")
            throw ChatServiceError.networkError(error.localizedDescription)
        }
    }
    
    /// 생성된 일기 데이터 저장
    func saveGeneratedDiary(sessionId: UUID, data: GeneratedDiaryData) {
        generatedDiaryDataCache[sessionId] = data
        print("💾 Cached generated diary for session: \(sessionId)")
    }

    /// 저장된 일기 데이터 가져오기
    func getGeneratedDiary(sessionId: UUID) -> GeneratedDiaryData? {
        return generatedDiaryDataCache[sessionId]
    }

    /// 일기 데이터 삭제 (저장 완료 후 호출)
    func clearGeneratedDiary(sessionId: UUID) {
        generatedDiaryDataCache.removeValue(forKey: sessionId)
        print("🗑️ Cleared generated diary cache for session: \(sessionId)")
    }

    /// 일기 생성 여부 확인
    func isDiaryGenerated(sessionId: UUID) -> Bool {
        return generatedDiaryDataCache[sessionId] != nil
    }
    
    // MARK: - Post Deletion
    func handlePostDeletion(postId: Int, date: Date) async throws {
        let dateString = formatDate(date)
        print("🗑️ Handling post deletion for \(dateString)")
        
        do {
            try await supabase.rpc(
                "handle_post_deletion",
                params: [
                    "p_post_id": AnyJSON(postId),
                    "p_date": AnyJSON(dateString)
                ]
            ).execute()
            
            // Clear permission cache (needs recheck)
            clearCache()
//            permissionCache.removeValue(forKey: dateString)
            
            print("✅ Post deletion handled")
            
        } catch {
            print("❌ Post deletion handling failed: \(error)")
            throw ChatServiceError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Cache Management
    func clearCache() {
        sessionCache.removeAll()
        messageCache.removeAll()
        permissionCache.removeAll()
        sessionInfoCache.removeAll()
        noSessionCache.removeAll()  // Clear "no session" cache
        dateSessionsCache.removeAll()
        generatedDiaryDataCache.removeAll()
        
        currentSessionId = nil
        currentMessages = []
        currentMessageCount = 0
        
        print("🧹 ChatService: 모든 대화 데이터 초기화 완료")
    }
    
    func clearSessionCache(for characterId: Int, date: Date) {
        let dateString = formatDate(date)
        let cacheKey = "\(characterId)_\(dateString)"
        
        if let sessionId = sessionCache[cacheKey] {
            messageCache.removeValue(forKey: sessionId)
            sessionInfoCache.removeValue(forKey: sessionId)
        }
        
        sessionCache.removeValue(forKey: cacheKey)
        noSessionCache.remove(cacheKey)  // Also remove from "no session" cache
        permissionCache.removeValue(forKey: dateString)
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    func canSendMessage(sessionId: UUID) -> Bool {
        guard let messages = messageCache[sessionId] else { return true }
        let userMessageCount = messages.filter { $0.sender == .user }.count
        return userMessageCount < 10
    }
    
    func getRemainingMessages(sessionId: UUID) -> Int {
        guard let messages = messageCache[sessionId] else { return 10 }
        let userMessageCount = messages.filter { $0.sender == .user }.count
        return max(0, 10 - userMessageCount)
    }
    
    // MARK: - Debug Helpers
    func printCacheStatus() {
        print("\n📊 Chat Cache Status")
        print("├─ Sessions: \(sessionCache.count)")
        print("├─ No Session Cache: \(noSessionCache.count)")
        print("├─ Message sets: \(messageCache.count)")
        print("├─ Permissions: \(permissionCache.count)")
        print("├─ Date Sessions: \(dateSessionsCache.count)")  // 🎯 NEW
        print("└─ Total messages: \(messageCache.values.reduce(0) { $0 + $1.count })\n")
    }
}

