//
//  CharacterObject.swift
//  DiaryFriend
//
//  LocalDB/Realm/Models/CharacterObject.swift
//  Character 데이터 Realm 모델
//

import Foundation
import RealmSwift

// MARK: - Realm Object
class CharacterObject: Object {
    // Primary Fields
    @Persisted var id: Int = 0
    @Persisted var name: String = ""
    @Persisted var koreanName: String?
    
    // Description Fields
    @Persisted var characterDescription: String?  // 'description'은 예약어라 변경
    @Persisted var koreanDescription: String?
    @Persisted var promptDescription: String?
    @Persisted var avatarUrl: String?
    
    // Personality (List)
    @Persisted var personalityList = List<String>()
    
    // Greeting Messages (Lists)
    @Persisted var koreanGreetings = List<String>()
    @Persisted var englishGreetings = List<String>()
    
    // User_Character Relationship
    @Persisted var userCharacterId: Int?
    @Persisted var isFollowing: Bool = false
    @Persisted var affinity: Int = 0
    
    // Metadata
    @Persisted var lastSynced: Date = Date()
    @Persisted var userId: String = ""  // 현재 사용자 ID (멀티 유저 대비)
    
    // Primary Key
    override static func primaryKey() -> String? {
        return "id"
    }
    
    // Indexed Properties (검색 성능 향상)
    override static func indexedProperties() -> [String] {
        return ["name", "koreanName", "isFollowing", "userId"]
    }
}

// MARK: - Conversion to Domain Model
extension CharacterObject {
    /// Realm Object → CharacterWithAffinity 변환
    func toCharacterWithAffinity() -> CharacterWithAffinity {
        // GreetingMessages 먼저 준비
        let greetingMessages: GreetingMessages? = {
            if !koreanGreetings.isEmpty || !englishGreetings.isEmpty {
                return GreetingMessages(
                    Korean: koreanGreetings.isEmpty ? nil : Array(koreanGreetings),
                    English: englishGreetings.isEmpty ? nil : Array(englishGreetings)
                )
            }
            return nil
        }()
        
        // User_Character 관계 준비
        let userCharacterRelations: [UserCharacterRelation]? = {
            if let ucId = userCharacterId {
                return [UserCharacterRelation(
                    id: ucId,
                    is_following: isFollowing,
                    affinity: affinity
                )]
            }
            return nil
        }()
        
        // Character 생성 (모든 값을 초기화 시점에 설정)
        let character = CharacterWithAffinity(
            id: id,
            name: name,
            korean_name: koreanName,
            personality: personalityList.isEmpty ? nil : Array(personalityList),
            description: characterDescription,
            korean_description: koreanDescription,
            prompt_description: promptDescription,
            avatar_url: avatarUrl,
            greeting_messages: greetingMessages,  // 초기화 시점에 설정
            User_Character: userCharacterRelations  // 초기화 시점에 설정
        )
        
        return character
    }
}

// MARK: - Conversion from Domain Model
extension CharacterWithAffinity {
    /// CharacterWithAffinity → Realm Object 변환
    func toRealmObject(userId: String? = nil) -> CharacterObject {
        let realmObject = CharacterObject()
        
        // Basic fields
        realmObject.id = id
        realmObject.name = name
        realmObject.koreanName = korean_name
        realmObject.characterDescription = description
        realmObject.koreanDescription = korean_description
        realmObject.promptDescription = prompt_description
        realmObject.avatarUrl = avatar_url
        
        // Personality array → List
        if let personality = personality {
            realmObject.personalityList.removeAll()
            realmObject.personalityList.append(objectsIn: personality)
        }
        
        // Greeting messages → Lists
        if let koreanMsgs = greeting_messages?.Korean {
            realmObject.koreanGreetings.removeAll()
            realmObject.koreanGreetings.append(objectsIn: koreanMsgs)
        }
        
        if let englishMsgs = greeting_messages?.English {
            realmObject.englishGreetings.removeAll()
            realmObject.englishGreetings.append(objectsIn: englishMsgs)
        }
        
        // User_Character relationship
        if let userCharacter = User_Character?.first {
            realmObject.userCharacterId = userCharacter.id
            realmObject.isFollowing = userCharacter.is_following
            realmObject.affinity = userCharacter.affinity
        }
        
        // Metadata
        realmObject.lastSynced = Date()
        
        // User ID (제공되거나 현재 사용자)
        if let userId = userId {
            realmObject.userId = userId
        } else if let currentUserId = SupabaseManager.shared.currentUser?.id.uuidString {
            realmObject.userId = currentUserId
        }
        
        return realmObject
    }
}

// MARK: - Batch Operations Helper
extension CharacterObject {
    /// 동기화 필요 여부 체크
    func needsSync(threshold: TimeInterval = 3600) -> Bool {
        // 1시간 이상 지났으면 동기화 필요
        return Date().timeIntervalSince(lastSynced) > threshold
    }
    
    /// 친밀도 업데이트 (로컬)
    func updateAffinity(_ newValue: Int) {
        // Realm write transaction 내에서만 호출
        self.affinity = newValue
        self.lastSynced = Date()
    }
    
    /// 팔로우 상태 변경 (로컬)
    func updateFollowStatus(_ following: Bool) {
        // Realm write transaction 내에서만 호출
        self.isFollowing = following
        self.lastSynced = Date()
    }
}

// MARK: - Query Helpers
extension CharacterObject {
    /// 팔로우 중인 캐릭터만 조회
    static func followingCharacters(in realm: Realm) -> Results<CharacterObject> {
        return realm.objects(CharacterObject.self)
            .filter("isFollowing == true")
            .sorted(byKeyPath: "affinity", ascending: false)
    }
    
    /// 특정 사용자의 캐릭터만 조회
    static func charactersForUser(_ userId: String, in realm: Realm) -> Results<CharacterObject> {
        return realm.objects(CharacterObject.self)
            .filter("userId == %@", userId)
            .sorted(byKeyPath: "name", ascending: true)
    }
}
