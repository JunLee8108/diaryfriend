//
//  CharacterService.swift
//  DiaryFriend
//
//  Character 테이블 Supabase 서비스
//

import Foundation
import Supabase

// MARK: - Models

// greeting_messages 구조체
struct GreetingMessages: Codable {
    let Korean: [String]?
    let English: [String]?
}

struct CharacterWithAffinity: Codable {
    let id: Int
    let name: String
    let korean_name: String?
    let personality: [String]?
    let description: String?
    let korean_description: String?
    let prompt_description: String?
    let avatar_url: String?
    let greeting_messages: GreetingMessages?
    let category: String?
    var User_Character: [UserCharacterRelation]?
    
    // Computed properties
    var affinity: Int {
        User_Character?.first?.affinity ?? 0
    }
    
    var isFollowing: Bool {
        User_Character?.first?.is_following ?? false
    }
    
    var userCharacterId: Int? {
        User_Character?.first?.id
    }

    /// 유저가 이 캐릭터에 대해 마지막으로 확인(해금 애니메이션 재생)한 친밀도
    var lastSeenAffinity: Int {
        User_Character?.first?.last_seen_affinity ?? 0
    }
    
    // 한국어 인사말 가져오기
    var koreanGreetings: [String] {
        greeting_messages?.Korean ?? []
    }
    
    // 영어 인사말 가져오기
    var englishGreetings: [String] {
        greeting_messages?.English ?? []
    }
}

// Identifiable 프로토콜 추가 (sheet item용)
extension CharacterWithAffinity: Identifiable { }

// MARK: - Localization Support
extension CharacterWithAffinity {
    /// 현재 언어에 맞는 이름 반환
    func localizedName(isKorean: Bool) -> String {
        if isKorean, let koreanName = korean_name, !koreanName.isEmpty {
            return koreanName
        }
        return name
    }
    
    /// 현재 언어에 맞는 설명 반환
    func localizedDescription(isKorean: Bool) -> String? {
        if isKorean, let koreanDesc = korean_description, !koreanDesc.isEmpty {
            return koreanDesc
        }
        return description
    }
    
    func localizedPersonalities(isKorean: Bool) -> [String] {
        guard isKorean, let personalities = personality else {
            return personality ?? []
        }
        
        return personalities.map { eng in
            let keyString = "personality.\(eng.lowercased())"
            if let key = LocalizationKey(rawValue: keyString) {
                return LocalizationManager.shared.localized(key)
            }
            return eng // 매핑이 없으면 원본 영어 반환
        }
    }
    
    /// 현재 언어에 맞는 인사말 반환
    func localizedGreetings(isKorean: Bool) -> [String] {
        if isKorean {
            return koreanGreetings.isEmpty ? englishGreetings : koreanGreetings
        }
        return englishGreetings.isEmpty ? koreanGreetings : englishGreetings
    }
}

struct UserCharacterRelation: Codable {
    let id: Int
    var is_following: Bool
    var affinity: Int
    var last_seen_affinity: Int?
}

// MARK: - Character Image (친밀도별 해금 이미지)
struct CharacterImage: Codable, Identifiable {
    let id: Int
    let character_id: Int
    let image_url: String
    let display_order: Int
    let unlock_affinity: Int
}

// Follow 토글 결과
struct FollowToggleResult {
    let userCharacterId: Int
    let isFollowing: Bool
    let action: FollowAction
}

enum FollowAction {
    case created
    case updated
}

// MARK: - Service
class CharacterService {
    private let supabase = SupabaseManager.shared.client
    
    private var currentUserId: UUID? {
        SupabaseManager.shared.currentUser?.id
    }
    
    // MARK: - Fetch Operations
    
    /// 전체 캐릭터 목록 가져오기 (User_Character 관계 포함)
    func fetchAllCharacters() async throws -> [CharacterWithAffinity] {
        guard let userId = currentUserId else {
            throw CharacterError.notAuthenticated
        }
        
        // React처럼 캐릭터 필터링 조건 사용
        // 모든 캐릭터를 가져오려면 is_system_default 필드 활용
        let query = """
        id,
        name,
        korean_name,
        personality,
        description,
        korean_description,
        prompt_description,
        avatar_url,
        greeting_messages,
        category,
        User_Character (
            id,
            is_following,
            affinity
        )
        """

        let characters: [CharacterWithAffinity] = try await supabase
            .from("Character")
            .select(query)
            .or("is_system_default.eq.true")  // 모든 시스템 캐릭터
            .eq("User_Character.user_id", value: userId.uuidString)
            .order("name")
            .execute()
            .value
        
        return characters
    }
    
    /// 특정 캐릭터 정보 가져오기
    func fetchCharacter(id: Int) async throws -> CharacterWithAffinity {
        guard let userId = currentUserId else {
            throw CharacterError.notAuthenticated
        }
        
        let query = """
        id,
        name,
        korean_name,
        personality,
        description,
        korean_description,
        prompt_description,
        avatar_url,
        greeting_messages,
        category,
        User_Character (
            id,
            is_following,
            affinity
        )
        """

        let character: CharacterWithAffinity = try await supabase
            .from("Character")
            .select(query)
            .eq("id", value: id)
            .eq("User_Character.user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        return character
    }
    
    /// 여러 캐릭터 일괄 조회
    func fetchCharacters(ids: [Int]) async throws -> [CharacterWithAffinity] {
        guard let userId = currentUserId else {
            throw CharacterError.notAuthenticated
        }
        
        guard !ids.isEmpty else { return [] }
        
        let query = """
        id,
        name,
        korean_name,
        avatar_url,
        User_Character (
            id,
            affinity,
            is_following
        )
        """
        
        let characters: [CharacterWithAffinity] = try await supabase
            .from("Character")
            .select(query)
            .in("id", values: ids)
            .eq("User_Character.user_id", value: userId.uuidString)
            .execute()
            .value
        
        return characters
    }
    
    // MARK: - Follow Operations
    
    /// 캐릭터 팔로우 토글
    func toggleFollow(characterId: Int) async throws -> FollowToggleResult {
        guard let userId = currentUserId else {
            throw CharacterError.notAuthenticated
        }
        
        // 1. 기존 레코드 확인
        let existingRecords: [UserCharacterRelation] = try await supabase
            .from("User_Character")
            .select("id, is_following, affinity")
            .eq("user_id", value: userId.uuidString)
            .eq("character_id", value: characterId)
            .execute()
            .value
        
        if let existing = existingRecords.first {
            // 레코드가 있으면 토글
            let newFollowingState = !existing.is_following
            
            struct UpdateData: Codable {
                let is_following: Bool
            }
            
            try await supabase
                .from("User_Character")
                .update(UpdateData(is_following: newFollowingState))
                .eq("id", value: existing.id)
                .execute()
            
            print("✅ Follow 토글: Character \(characterId) → \(newFollowingState)")
            
            return FollowToggleResult(
                userCharacterId: existing.id,
                isFollowing: newFollowingState,
                action: .updated
            )
        } else {
            // 레코드가 없으면 새로 생성 (is_following: true)
            struct NewRelation: Codable {
                let user_id: String
                let character_id: Int
                let is_following: Bool
                let affinity: Int
            }
            
            let newRelation = NewRelation(
                user_id: userId.uuidString,
                character_id: characterId,
                is_following: true,
                affinity: 0
            )
            
            let createdRecords: [UserCharacterRelation] = try await supabase
                .from("User_Character")
                .insert(newRelation)
                .select("id, is_following, affinity")
                .execute()
                .value
            
            guard let created = createdRecords.first else {
                throw CharacterError.updateFailed("Failed to create new relation")
            }
            
            print("✅ Follow 생성: Character \(characterId)")
            
            return FollowToggleResult(
                userCharacterId: created.id,
                isFollowing: true,
                action: .created
            )
        }
    }

    // MARK: - Character Images (친밀도별 해금 이미지)

    /// 캐릭터별 해금 가능 이미지 목록 조회 (display_order 오름차순)
    func fetchCharacterImages(characterId: Int) async throws -> [CharacterImage] {
        let images: [CharacterImage] = try await supabase
            .from("Character_Image")
            .select("id, character_id, image_url, display_order, unlock_affinity")
            .eq("character_id", value: characterId)
            .order("display_order", ascending: true)
            .execute()
            .value

        return images
    }

    /// 유저가 마지막으로 확인한 친밀도 값을 서버에 기록
    func updateLastSeenAffinity(characterId: Int, affinity: Int) async throws {
        guard let userId = currentUserId else {
            throw CharacterError.notAuthenticated
        }

        try await supabase
            .from("User_Character")
            .update(["last_seen_affinity": affinity])
            .eq("character_id", value: characterId)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
}

// MARK: - Errors
enum CharacterError: LocalizedError {
    case notAuthenticated
    case notFound
    case updateFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "로그인이 필요합니다"
        case .notFound:
            return "캐릭터를 찾을 수 없습니다"
        case .updateFailed(let message):
            return "업데이트 실패: \(message)"
        }
    }
}
