//
//  RealmManager.swift
//  DiaryFriend
//
//  LocalDB/Realm/RealmManager.swift
//  Realm 데이터베이스 관리
//

import Foundation
import RealmSwift

actor RealmManager {
    static let shared = RealmManager()
    private var realm: Realm?
    private var currentUserId: String?
    
    // MARK: - Setup & User Management
    
    /// 사용자별 Realm 초기화
    func setupRealm(for userId: String?) async {
        do {
            let config = RealmConfiguration.shared.configurationForUser(userId)
            self.realm = try await Realm(configuration: config, actor: self)
            self.currentUserId = userId
            
            Logger.debug("✅ Initialized for user \(userId?.prefix(8) ?? "temporary")")
        } catch {
            Logger.debug("❌ Initialization failed - \(error)")
        }
    }
    
    /// 사용자 전환
    func switchUser(_ userId: String?) async throws {
        // 기존 Realm 닫기
        self.realm = nil
        
        // 새 사용자로 초기화
        await setupRealm(for: userId)
        
        print("🔄 RealmManager: Switched to user \(userId?.prefix(8) ?? "temporary")")
    }
    
    /// 현재 사용자 확인
    func getCurrentUserId() -> String? {
        return currentUserId
    }
    
    // MARK: - Post Detail Management (추가)
    
    /// PostDetail 캐시 전체 삭제
    func clearAllPostDetails() async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            let cachedPosts = realm.objects(PostObject.self)
                .filter("userId == %@ AND isCached == true", userId)
            
            for post in cachedPosts {
                post.comments.removeAll()
                post.hashtags.removeAll()
                post.isCached = false
            }
        }
        
        print("🗑️ RealmManager: Cleared all post detail cache")
    }
    
    // MARK: - Character CRUD Operations
    
    /// 모든 캐릭터 저장/업데이트
    func saveCharacters(_ characters: [CharacterWithAffinity]) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }

        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""

        try await realm.asyncWrite {
            for character in characters {
                let realmObject = character.toRealmObject(userId: userId)
                // lastSeenAffinity / needsServerSync 병합
                applyLastSeenMerge(for: character, into: realmObject, realm: realm)
                realm.add(realmObject, update: .modified)
            }
        }

        print("💾 RealmManager: \(characters.count)개 캐릭터 저장 완료")
    }

    /// 단일 캐릭터 저장/업데이트
    func saveCharacter(_ character: CharacterWithAffinity) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }

        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""

        try await realm.asyncWrite {
            let realmObject = character.toRealmObject(userId: userId)
            applyLastSeenMerge(for: character, into: realmObject, realm: realm)
            realm.add(realmObject, update: .modified)
        }
        
        print("💾 RealmManager: 캐릭터 '\(character.name)' 저장 완료")
    }
    
    /// 모든 캐릭터 조회
    func getAllCharacters() async -> [CharacterWithAffinity] {
        guard let realm = realm else { return [] }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        let objects = realm.objects(CharacterObject.self)
            .filter("userId == %@", userId)
            .sorted(byKeyPath: "name", ascending: true)
        
        return objects.map { $0.toCharacterWithAffinity() }
    }
    
    /// ID로 캐릭터 조회
    func getCharacter(id: Int) async -> CharacterWithAffinity? {
        guard let realm = realm else { return nil }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        return realm.objects(CharacterObject.self)
            .filter("id == %@ AND userId == %@", id, userId)
            .first?
            .toCharacterWithAffinity()
    }
    
    /// 여러 ID로 캐릭터 조회
    func getCharacters(ids: [Int]) async -> [CharacterWithAffinity] {
        guard let realm = realm else { return [] }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        let objects = realm.objects(CharacterObject.self)
            .filter("id IN %@ AND userId == %@", ids, userId)
        
        return objects.map { $0.toCharacterWithAffinity() }
    }
    
    /// 팔로잉 중인 캐릭터만 조회
    func getFollowingCharacters() async -> [CharacterWithAffinity] {
        guard let realm = realm else { return [] }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        let objects = realm.objects(CharacterObject.self)
            .filter("userId == %@ AND isFollowing == true", userId)
            .sorted(byKeyPath: "affinity", ascending: false)
        
        return objects.map { $0.toCharacterWithAffinity() }
    }
    
    /// 팔로우 상태 업데이트
    func updateFollowStatus(characterId: Int, isFollowing: Bool) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            if let character = realm.objects(CharacterObject.self)
                .filter("id == %@ AND userId == %@", characterId, userId)
                .first {
                character.isFollowing = isFollowing
                character.lastSynced = Date()
            }
        }
        
        print("🔄 RealmManager: 캐릭터 \(characterId) 팔로우 상태 → \(isFollowing)")
    }
    
    func updateUserCharacterId(
        characterId: Int,
        userCharacterId: Int
    ) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        try await realm.asyncWrite {
            if let character = realm.objects(CharacterObject.self)
                .filter("id == %@", characterId)
                .first {
                character.userCharacterId = userCharacterId
                character.lastSynced = Date()
            }
        }
        
        print("🔄 RealmManager: 캐릭터 \(characterId) userCharacterId → \(userCharacterId)")
    }
    
    /// 친밀도 업데이트
    func updateAffinity(characterId: Int, affinity: Int) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            if let character = realm.objects(CharacterObject.self)
                .filter("id == %@ AND userId == %@", characterId, userId)
                .first {
                character.affinity = affinity
                character.lastSynced = Date()
            }
        }
        
        print("🔄 RealmManager: 캐릭터 \(characterId) 친밀도 → \(affinity)")
    }
    
    /// 캐릭터 삭제
    func deleteCharacter(id: Int) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            if let character = realm.objects(CharacterObject.self)
                .filter("id == %@ AND userId == %@", id, userId)
                .first {
                realm.delete(character)
            }
        }
        
        print("🗑️ RealmManager: 캐릭터 \(id) 삭제 완료")
    }
    
    // MARK: - Post Search
    
    func searchPosts(query: String) async -> [Post] {
        guard let realm = realm else { return [] }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        // Realm 최적화 쿼리 - 인덱스 활용
        let objects = realm.objects(PostObject.self)
            .filter(
                "userId == %@ AND (content CONTAINS[c] %@ OR mood CONTAINS[c] %@ OR entryDate CONTAINS %@)",
                userId, query, query, query
            )
            .sorted(byKeyPath: "entryDate", ascending: false)
        
        return objects.map { $0.toPost() }
    }
    
    // MARK: - Post CRUD Operations
    
    /// 여러 포스트 저장/업데이트 (기본 정보만)
    func savePosts(_ posts: [Post]) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            for post in posts {
                let realmObject = post.toRealmObject(userId: userId)
                realm.add(realmObject, update: .modified)
            }
        }
        
        print("💾 RealmManager: \(posts.count)개 포스트 저장 완료")
    }
    
    /// 포스트 상세 정보 저장/업데이트
    func savePostDetail(_ postDetail: PostDetail) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            let realmObject = postDetail.toRealmObject(userId: userId)
            realm.add(realmObject, update: .modified)
        }
        
        print("💾 RealmManager: 포스트 상세 저장 (ID: \(postDetail.id), 댓글: \(postDetail.Comment?.count ?? 0)개)")
    }
    
    /// 날짜 범위로 포스트 조회
    func getPostsForDateRange(from startDate: String, to endDate: String) async -> [Post] {
        guard let realm = realm else { return [] }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        let objects = realm.objects(PostObject.self)
            .filter("userId == %@ AND entryDate >= %@ AND entryDate <= %@",
                    userId, startDate, endDate)
            .sorted(byKeyPath: "entryDate", ascending: false)
        
        return objects.map { $0.toPost() }
    }
    
    /// 특정 월의 포스트 조회
    func getPostsForMonth(_ monthKey: String) async -> [Post] {
        guard let realm = realm else { return [] }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        let objects = realm.objects(PostObject.self)
            .filter("userId == %@ AND entryDate BEGINSWITH %@", userId, monthKey)
            .sorted(byKeyPath: "entryDate", ascending: false)
        
        return objects.map { $0.toPost() }
    }
    
    /// ID로 포스트 상세 조회
    func getPostDetail(id: Int) async -> PostDetail? {
        guard let realm = realm else { return nil }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        // 🆕 네트워크 상태 확인
        let isOnline = await MainActor.run {
            NetworkMonitor.shared.isConnected
        }
        
        if isOnline {
            // ✅ 온라인: isCached == true인 완전한 PostDetail만 반환
            print("🌐 온라인 모드: isCached == true 필터 적용")
            return realm.objects(PostObject.self)
                .filter("id == %@ AND userId == %@ AND isCached == true", id, userId)
                .first?
                .toPostDetail()
        } else {
            // ✈️ 오프라인: isCached 무시하고 기본 Post 정보라도 반환
            print("✈️ 오프라인 모드: isCached 필터 제거")
            
            if let postObject = realm.objects(PostObject.self)
                .filter("id == %@ AND userId == %@", id, userId)
                .first {
                
                if postObject.isCached {
                    print("💾 완전한 PostDetail 반환 (ID: \(id))")
                } else {
                    print("⚠️ 제한된 PostDetail 반환 (ID: \(id)) - 댓글/해시태그/이미지 없음")
                }
                
                return postObject.toPostDetail()
            }
            
            print("❌ Realm에 Post 없음 (ID: \(id))")
            return nil
        }
    }
    
    /// ID로 포스트 기본 정보 조회
    func getPost(id: Int) async -> Post? {
        guard let realm = realm else { return nil }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        return realm.objects(PostObject.self)
            .filter("id == %@ AND userId == %@", id, userId)
            .first?
            .toPost()
    }
    
    /// 특정 날짜의 포스트 조회
    func getPostsForDate(_ dateString: String) async -> [Post] {
        guard let realm = realm else { return [] }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        let objects = realm.objects(PostObject.self)
            .filter("userId == %@ AND entryDate == %@", userId, dateString)
            .sorted(byKeyPath: "createdAt", ascending: false)
        
        return objects.map { $0.toPost() }
    }
    
    /// 포스트 업데이트
    func updatePost(id: Int, content: String? = nil, mood: String? = nil) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            if let post = realm.objects(PostObject.self)
                .filter("id == %@ AND userId == %@", id, userId)
                .first {
                if let content = content {
                    post.content = content
                }
                if let mood = mood {
                    post.mood = mood
                }
                // ISO8601 형식으로 현재 시간 저장
                let formatter = ISO8601DateFormatter()
                post.updatedAt = formatter.string(from: Date())
                post.lastSynced = Date()
            }
        }
        
        print("📝 RealmManager: 포스트 \(id) 업데이트 완료")
    }
    
    /// 포스트 삭제
    func deletePost(id: Int) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            if let post = realm.objects(PostObject.self)
                .filter("id == %@ AND userId == %@", id, userId)
                .first {
                realm.delete(post)
            }
        }
        
        print("🗑️ RealmManager: 포스트 \(id) 삭제 완료")
    }

    /// 특정 댓글 삭제 (PostObject 내 EmbeddedObject)
    func deleteComment(commentId: Int, postId: Int) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }

        try await realm.asyncWrite {
            if let post = realm.objects(PostObject.self).filter("id == %@", postId).first,
               let index = post.comments.firstIndex(where: { $0.id == commentId }) {
                post.comments.remove(at: index)
            }
        }

        print("🗑️ RealmManager: 댓글 \(commentId) 삭제 완료 (Post \(postId))")
    }

    /// 여러 포스트 일괄 삭제 (성능 최적화)
    func deletePosts(ids: [Int]) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        guard !ids.isEmpty else {
            print("⚠️ RealmManager: 삭제할 ID 목록이 비어있음")
            return
        }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            let postsToDelete = realm.objects(PostObject.self)
                .filter("id IN %@ AND userId == %@", ids, userId)
            
            let deleteCount = postsToDelete.count
            realm.delete(postsToDelete)
            
            print("🗑️ RealmManager: \(deleteCount)개 포스트 일괄 삭제 완료")
        }
    }
    
    // MARK: - Post Cache Management
    
    /// 포스트가 있는 날짜들 가져오기 (캘린더용)
    func getPostDates() async -> Set<String> {
        guard let realm = realm else { return [] }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        let dates = realm.objects(PostObject.self)
            .filter("userId == %@", userId)
            .distinct(by: ["entryDate"])
            .map { $0.entryDate }
        
        return Set(dates)
    }
    
    /// 캐시된 월 목록 가져오기
    func getCachedMonths() async -> Set<String> {
        guard let realm = realm else { return [] }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        let posts = realm.objects(PostObject.self)
            .filter("userId == %@", userId)
        
        var months = Set<String>()
        for post in posts {
            let monthKey = String(post.entryDate.prefix(7))
            months.insert(monthKey)
        }
        
        return months
    }
    
    /// 포스트 마지막 동기화 시간
    func getPostLastSyncDate(for monthKey: String) async -> Date? {
        guard let realm = realm else { return nil }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        return realm.objects(PostObject.self)
            .filter("userId == %@ AND entryDate BEGINSWITH %@", userId, monthKey)
            .sorted(byKeyPath: "lastSynced", ascending: false)
            .first?.lastSynced
    }
    
    /// 동기화 필요한 포스트 확인
    func getPostsNeedingSync(threshold: TimeInterval = 3600) async -> [Int] {
        guard let realm = realm else { return [] }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        let cutoffDate = Date().addingTimeInterval(-threshold)
        
        return realm.objects(PostObject.self)
            .filter("userId == %@ AND lastSynced < %@", userId, cutoffDate)
            .map { $0.id }
    }
    
    /// 오래된 포스트 정리
    func cleanupOldPosts(olderThan days: Int = 90) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let cutoffString = DateUtility.shared.dateString(from: cutoffDate)
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            let oldPosts = realm.objects(PostObject.self)
                .filter("userId == %@ AND entryDate < %@", userId, cutoffString)
            realm.delete(oldPosts)
        }
        
        print("🧹 RealmManager: \(days)일 이상 된 포스트 정리 완료")
    }
    
    /// 전체 포스트 캐시 삭제
    func clearAllPosts() async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            let allPosts = realm.objects(PostObject.self)
                .filter("userId == %@", userId)
            realm.delete(allPosts)
        }
        
        print("🗑️ RealmManager: 모든 포스트 캐시 삭제 완료")
    }
    
    // MARK: - General Cache Management
    
    /// 마지막 동기화 시간 확인 (캐릭터)
    func getLastSyncDate() async -> Date? {
        guard let realm = realm else { return nil }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        return realm.objects(CharacterObject.self)
            .filter("userId == %@", userId)
            .sorted(byKeyPath: "lastSynced", ascending: false)
            .first?.lastSynced
    }
    
    /// 동기화 필요한 캐릭터 확인
    func getCharactersNeedingSync(threshold: TimeInterval = 3600) async -> [Int] {
        guard let realm = realm else { return [] }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        let cutoffDate = Date().addingTimeInterval(-threshold)
        
        return realm.objects(CharacterObject.self)
            .filter("userId == %@ AND lastSynced < %@", userId, cutoffDate)
            .map { $0.id }
    }
    
    /// 오래된 캐릭터 정리
    func cleanupOldCharacters(olderThan days: Int = 30) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            let oldCharacters = realm.objects(CharacterObject.self)
                .filter("userId == %@ AND lastSynced < %@", userId, cutoffDate)
            realm.delete(oldCharacters)
        }
        
        print("🧹 RealmManager: \(days)일 이상 된 캐릭터 데이터 정리 완료")
    }
    
    /// 전체 캐릭터 캐시 삭제
    func clearAllCharacters() async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }
        
        let userId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
        
        try await realm.asyncWrite {
            let allCharacters = realm.objects(CharacterObject.self)
                .filter("userId == %@", userId)
            realm.delete(allCharacters)
        }

        print("🗑️ RealmManager: 모든 캐릭터 캐시 삭제 완료")
    }

    // MARK: - Character Image Unlock Sync (lastSeenAffinity + needsServerSync)

    /// 서버 fetch 결과를 Realm 에 적용할 때 호출되는 병합 헬퍼.
    /// 기존 row 가 dirty(needsServerSync == true) 상태면 local 값을 보존,
    /// 아니면 server 값을 수용한다.
    ///
    /// MUST 을 realm.asyncWrite 블록 안에서만 호출할 것.
    private func applyLastSeenMerge(
        for character: CharacterWithAffinity,
        into realmObject: CharacterObject,
        realm: Realm
    ) {
        let serverValue = character.User_Character?.first?.last_seen_affinity ?? 0

        if let existing = realm.object(ofType: CharacterObject.self, forPrimaryKey: character.id),
           existing.needsServerSync {
            // Dirty: 로컬 변경사항 보존
            realmObject.lastSeenAffinity = existing.lastSeenAffinity
            realmObject.needsServerSync = true
        } else {
            // Clean: 서버 값 수용
            realmObject.lastSeenAffinity = serverValue
            realmObject.needsServerSync = false
        }
    }

    /// 해금 애니메이션 후 last_seen_affinity 업데이트 (3-tier write 의 Realm 단계)
    func updateLastSeenAffinity(
        characterId: Int,
        affinity: Int,
        needsSync: Bool
    ) async throws {
        guard let realm = realm else { throw RealmError.notInitialized }
        try await realm.asyncWrite {
            if let obj = realm.object(ofType: CharacterObject.self, forPrimaryKey: characterId) {
                obj.lastSeenAffinity = affinity
                obj.needsServerSync = needsSync
                obj.lastSynced = Date()
            }
        }
    }

    /// 서버 sync 성공 후 dirty flag 해제
    func clearSyncFlag(characterId: Int) async throws {
        guard let realm = realm else { throw RealmError.notInitialized }
        try await realm.asyncWrite {
            if let obj = realm.object(ofType: CharacterObject.self, forPrimaryKey: characterId) {
                obj.needsServerSync = false
            }
        }
    }

    /// 서버와 sync 안 된 row 들 조회 (flush 대상)
    struct PendingAcknowledgment {
        let characterId: Int
        let lastSeenAffinity: Int
    }

    func getDirtyAcknowledgments() async -> [PendingAcknowledgment] {
        guard let realm = realm else { return [] }
        let objects = realm.objects(CharacterObject.self)
            .filter("needsServerSync == true")
        return objects.map {
            PendingAcknowledgment(
                characterId: $0.id,
                lastSeenAffinity: $0.lastSeenAffinity
            )
        }
    }
}

// MARK: - Error Types
enum RealmError: LocalizedError {
    case notInitialized
    case writeFailed
    case readFailed
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Realm is not initialized"
        case .writeFailed:
            return "Failed to write data"
        case .readFailed:
            return "Failed to read data"
        }
    }
}
