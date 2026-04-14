////
////  CharacterStore.swift
////  DiaryFriend
////
////  캐릭터 정보 중앙 관리 (메모리 캐시)
////


import Foundation
import SwiftUI

@MainActor
class CharacterStore: ObservableObject {
    static let shared = CharacterStore()
    private init() {}
    
    // MARK: - Published Properties
    @Published private(set) var allCharacters: [CharacterWithAffinity] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Private Properties
    private var characterCache: [Int: CharacterWithAffinity] = [:]
    private let service = CharacterService()
    private let realmManager = RealmManager.shared
    
    // MARK: - Computed Properties
    
    /// 팔로우 중인 캐릭터들
    var followingCharacters: [CharacterWithAffinity] {
        allCharacters.filter { $0.isFollowing }
    }
    
    /// 친밀도 순으로 정렬된 캐릭터들
    var charactersByAffinity: [CharacterWithAffinity] {
        allCharacters.sorted { $0.affinity > $1.affinity }
    }
    
    /// 팔로우하지 않는 캐릭터들
    var notFollowingCharacters: [CharacterWithAffinity] {
        allCharacters.filter { !$0.isFollowing }
    }

    /// Modern 캐릭터들
    var modernCharacters: [CharacterWithAffinity] {
        allCharacters.filter { ($0.category ?? "modern") != "classic" }
    }

    /// Classic 캐릭터들
    var classicCharacters: [CharacterWithAffinity] {
        allCharacters.filter { $0.category == "classic" }
    }
    
    // MARK: - Load Operations
    
    /// 전체 캐릭터 목록 로드 (Realm 캐시 우선, 메모리 캐시 그 다음)
    func loadAllCharacters() async {
        // 1. 메모리 캐시 확인
        if !allCharacters.isEmpty {
            print("💾 CharacterStore: 메모리 캐시 사용 (\(allCharacters.count)개)")
            return
        }
        
        // 2. Realm 캐시 확인
        let cachedCharacters = await realmManager.getAllCharacters()
        if !cachedCharacters.isEmpty {
            print("💾 CharacterStore: Realm 캐시 사용 (\(cachedCharacters.count)개)")
            self.allCharacters = cachedCharacters
            self.characterCache = Dictionary(
                uniqueKeysWithValues: cachedCharacters.map { ($0.id, $0) }
            )
            
            // 백그라운드에서 서버 동기화 확인
            Task.detached { [weak self] in
                await self?.syncCharactersInBackground()
            }
            return
        }
        
        // 3. 캐시가 없으면 서버에서 로드
        await refreshAllCharacters()
    }
    
    /// 서버에서 강제 새로고침
    func refreshAllCharacters() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 서버에서 가져오기
            let characters = try await service.fetchAllCharacters()
            
            // 메모리 캐시 업데이트
            self.allCharacters = characters
            self.characterCache = Dictionary(
                uniqueKeysWithValues: characters.map { ($0.id, $0) }
            )
            
            // Realm에 저장
            try await realmManager.saveCharacters(characters)
            
            print("✅ CharacterStore: 서버에서 \(characters.count)개 로드 및 캐시 완료")
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ CharacterStore 로드 실패: \(error)")
            
            // 서버 실패시 Realm 캐시라도 사용
            let cachedCharacters = await realmManager.getAllCharacters()
            if !cachedCharacters.isEmpty {
                self.allCharacters = cachedCharacters
                self.characterCache = Dictionary(
                    uniqueKeysWithValues: cachedCharacters.map { ($0.id, $0) }
                )
                print("⚠️ CharacterStore: 오프라인 모드 - Realm 캐시 사용")
            }
        }
        
        isLoading = false
    }
    
    /// 백그라운드 동기화
    private func syncCharactersInBackground() async {
        // 마지막 동기화 시간 확인
        if let lastSync = await realmManager.getLastSyncDate(),
           Date().timeIntervalSince(lastSync) < 3600 { // 1시간 이내면 스킵
            print("⏭️ CharacterStore: 최근 동기화됨, 스킵")
            return
        }
        
        // 서버에서 최신 데이터 가져오기
        do {
            let freshCharacters = try await service.fetchAllCharacters()
            
            // 변경사항이 있으면 업데이트
            if hasChanges(freshCharacters) {
                await MainActor.run {
                    self.allCharacters = freshCharacters
                    self.characterCache = Dictionary(
                        uniqueKeysWithValues: freshCharacters.map { ($0.id, $0) }
                    )
                }
                
                // Realm 업데이트
                try await realmManager.saveCharacters(freshCharacters)
                print("🔄 CharacterStore: 백그라운드 동기화 완료")
            }
        } catch {
            print("⚠️ CharacterStore: 백그라운드 동기화 실패 - \(error)")
        }
    }
    
    /// 변경사항 확인
    private func hasChanges(_ newCharacters: [CharacterWithAffinity]) -> Bool {
        // 개수가 다르면 변경됨
        if newCharacters.count != allCharacters.count {
            return true
        }
        
        // 친밀도나 팔로우 상태 변경 확인
        for newChar in newCharacters {
            if let oldChar = characterCache[newChar.id] {
                if oldChar.affinity != newChar.affinity ||
                    oldChar.isFollowing != newChar.isFollowing {
                    return true
                }
            } else {
                return true // 새 캐릭터
            }
        }
        
        return false
    }
    
    /// 특정 캐릭터 가져오기
    func getCharacter(id: Int) async -> CharacterWithAffinity? {
        // 1. 메모리 캐시 확인
        if let cached = characterCache[id] {
            print("💾 Character 메모리 캐시 히트: \(cached.korean_name ?? cached.name)")
            return cached
        }
        
        // 2. Realm 캐시 확인
        if let realmCached = await realmManager.getCharacter(id: id) {
            print("💾 Character Realm 캐시 히트: \(realmCached.korean_name ?? realmCached.name)")
            characterCache[id] = realmCached
            return realmCached
        }
        
        // 3. 서버에서 가져오기
        do {
            let character = try await service.fetchCharacter(id: id)
            
            // 캐시에 저장
            characterCache[id] = character
            try await realmManager.saveCharacter(character)
            
            // 전체 목록에도 추가 (없다면)
            if !allCharacters.contains(where: { $0.id == id }) {
                allCharacters.append(character)
            }
            
            return character
        } catch {
            print("❌ Character \(id) 가져오기 실패: \(error)")
            return nil
        }
    }
    
    /// 여러 캐릭터 일괄 조회
    func getCharacters(ids: [Int]) async -> [Int: CharacterWithAffinity] {
        var result: [Int: CharacterWithAffinity] = [:]
        var missingIds: [Int] = []
        
        // 1. 메모리 캐시에서 먼저
        for id in ids {
            if let cached = characterCache[id] {
                result[id] = cached
            } else {
                missingIds.append(id)
            }
        }
        
        // 2. Realm에서 누락된 것 확인
        if !missingIds.isEmpty {
            let realmCharacters = await realmManager.getCharacters(ids: missingIds)
            for character in realmCharacters {
                result[character.id] = character
                characterCache[character.id] = character
                missingIds.removeAll { $0 == character.id }
            }
        }
        
        // 3. 여전히 없는 것만 서버에서
        if !missingIds.isEmpty {
            do {
                let fetched = try await service.fetchCharacters(ids: missingIds)
                for character in fetched {
                    characterCache[character.id] = character
                    result[character.id] = character
                    
                    // Realm에도 저장
                    try await realmManager.saveCharacter(character)
                }
            } catch {
                print("❌ Characters 일괄 가져오기 실패: \(error)")
            }
        }
        
        return result
    }
    
    /// 동기 버전 (메모리에서만 조회)
    func getCharacterSync(id: Int) -> CharacterWithAffinity? {
        return characterCache[id]
    }
    
    // MARK: - Follow Operations
    
    /// 캐릭터 팔로우 토글
    @discardableResult
    func toggleFollowing(characterId: Int) async -> Bool? {
        do {
            // 서버 업데이트
            let result = try await service.toggleFollow(characterId: characterId)
            
            // 로컬 캐시 업데이트
            if let index = allCharacters.firstIndex(where: { $0.id == characterId }) {
                if result.action == .created {
                    // 새로 생성된 경우 - User_Character 배열 생성
                    let newRelation = UserCharacterRelation(
                        id: result.userCharacterId,
                        is_following: result.isFollowing,
                        affinity: 0
                    )
                    allCharacters[index].User_Character = [newRelation]
                    
                    // Realm에 userCharacterId 저장
                    try await realmManager.updateUserCharacterId(
                        characterId: characterId,
                        userCharacterId: result.userCharacterId
                    )
                } else {
                    // 기존 관계 업데이트 - 안전하게 처리
                    if var userChars = allCharacters[index].User_Character,
                       !userChars.isEmpty {
                        userChars[0].is_following = result.isFollowing
                        allCharacters[index].User_Character = userChars
                    }
                }
                
                characterCache[characterId] = allCharacters[index]
            }
            
            // Realm follow 상태 업데이트 (생성/업데이트 모두)
            try await realmManager.updateFollowStatus(
                characterId: characterId,
                isFollowing: result.isFollowing
            )
            
            return result.isFollowing
            
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Search & Filter
    
    /// 이름으로 캐릭터 검색
    func searchCharacters(query: String) -> [CharacterWithAffinity] {
        guard !query.isEmpty else { return allCharacters }
        
        let lowercased = query.lowercased()
        return allCharacters.filter { character in
            character.name.lowercased().contains(lowercased) ||
            (character.korean_name?.lowercased().contains(lowercased) ?? false)
        }
    }
    
    /// 친밀도 범위로 필터링
    func filterByAffinity(min: Int, max: Int) -> [CharacterWithAffinity] {
        allCharacters.filter { character in
            character.affinity >= min && character.affinity <= max
        }
    }
    
    // MARK: - Statistics
    
    /// 평균 친밀도
    var averageAffinity: Double {
        guard !allCharacters.isEmpty else { return 0 }
        let total = allCharacters.reduce(0) { $0 + $1.affinity }
        return Double(total) / Double(allCharacters.count)
    }
    
    /// 최고 친밀도 캐릭터
    var highestAffinityCharacter: CharacterWithAffinity? {
        allCharacters.max(by: { $0.affinity < $1.affinity })
    }
    
    /// 팔로우 통계
    var followStats: (following: Int, total: Int) {
        (following: followingCharacters.count, total: allCharacters.count)
    }
    
    // MARK: - Cache Management
    
    /// 캐시 정리
    func clearAllData() async {  // clearCache → clearAllData로 통일
        allCharacters.removeAll()
        characterCache.removeAll()
        errorMessage = nil
        
        do {
            try await realmManager.clearAllCharacters()
            print("🧹 CharacterStore: 모든 데이터 초기화 완료")
        } catch {
            print("❌ CharacterStore 초기화 실패: \(error)")
        }
    }
}
