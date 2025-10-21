//
//  StatsDataStore.swift
//  DiaryFriend
//
//  통계 화면용 데이터 스토어
//  ✅ Realm 캐시 우선 조회로 오프라인 지원 추가
//

import Foundation
import SwiftUI
import Combine

@MainActor
class StatsDataStore: ObservableObject {
    static let shared = StatsDataStore()
    
    @Published private(set) var cachedMonths: [String: [Post]] = [:]
    @Published private(set) var loadingMonth: String?
    @Published private(set) var errorMessage: String?
    
    private let postService = PostService()
    private let realmManager = RealmManager.shared  // ⭐ 추가
    
    // ⭐ Combine Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupPostChangeObserver()
    }
    
    // ⭐ 포스트 변경 이벤트 구독
    private func setupPostChangeObserver() {
        NotificationCenter.default
            .publisher(for: .postDidChange)
            .sink { [weak self] notification in
                self?.handlePostChange(notification)
            }
            .store(in: &cancellables)
        
        Logger.debug("📊 포스트 변경 이벤트 구독 시작")
    }
    
    // ⭐ 포스트 변경 처리
    private func handlePostChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let event = userInfo[PostChangeNotificationKey.event] as? PostChangeEvent,
              let date = userInfo[PostChangeNotificationKey.date] as? String else {
            return
        }
        
        // 날짜에서 월 추출 (YYYY-MM-DD → YYYY-MM)
        let monthKey = String(date.prefix(7))
        
        switch event {
        case .created(let postId, _):
            print("📊 StatsDataStore: Post \(postId) 생성 감지 - \(monthKey) 캐시 무효화")
            invalidateCache(for: monthKey)
            
        case .updated(let postId, _):
            print("📊 StatsDataStore: Post \(postId) 업데이트 감지 - \(monthKey) 캐시 무효화")
            invalidateCache(for: monthKey)
            
        case .deleted(let postId, _):
            print("📊 StatsDataStore: Post \(postId) 삭제 감지 - \(monthKey) 캐시 무효화")
            invalidateCache(for: monthKey)
        }
    }
    
    // ⭐ 특정 월 캐시 무효화
    private func invalidateCache(for monthKey: String) {
        if cachedMonths[monthKey] != nil {
            cachedMonths.removeValue(forKey: monthKey)
            print("   🗑️  \(monthKey) 메모리 캐시 제거됨")
            
            // ⭐ UI 업데이트를 위해 objectWillChange 발송
            objectWillChange.send()
        }
    }
    
    // MARK: - Computed Properties
    
    var isLoading: Bool {
        loadingMonth != nil
    }
    
    var cachedMonthCount: Int {
        cachedMonths.count
    }
    
    var cacheStatistics: String {
        let months = cachedMonths.keys.sorted().joined(separator: ", ")
        return "Cached months (\(cachedMonthCount)): \(months)"
    }
    
    // MARK: - Public Methods
    
    /// 특정 월의 포스트 가져오기 (캐시 우선)
    func posts(for date: Date) async -> [Post] {
        let monthKey = DateUtility.shared.monthKey(from: date)
        
        if let cached = cachedMonths[monthKey] {
            print("✅ StatsDataStore: 메모리 캐시 히트 - \(monthKey) (\(cached.count)개)")
            return cached
        }
        
        return await loadMonth(for: date)
    }
    
    /// 인접한 월들 프리페칭
    func prefetchAdjacent(to date: Date, range: Int = 2) async {
        let calendar = Calendar.current
        
        print("🔄 StatsDataStore: 인접 월 프리페칭 시작 (±\(range)개월)")
        
        for offset in -range...range where offset != 0 {
            guard let adjacentMonth = calendar.date(byAdding: .month, value: offset, to: date) else {
                continue
            }
            
            let monthKey = DateUtility.shared.monthKey(from: adjacentMonth)
            
            if cachedMonths[monthKey] != nil {
                print("   ⭐️  \(monthKey) - 이미 캐시됨")
                continue
            }
            
            _ = await loadMonth(for: adjacentMonth, silent: true)
        }
        
        print("✅ StatsDataStore: 인접 월 프리페칭 완료")
    }
    
    /// 오래된 캐시 정리
    func clearOldCache(keepRecent: Int = 12) {
        guard cachedMonths.count > keepRecent else {
            print("📊 StatsDataStore: 캐시 정리 불필요 (\(cachedMonths.count)/\(keepRecent))")
            return
        }
        
        let sortedKeys = cachedMonths.keys.sorted().reversed()
        let keysToKeep = Array(sortedKeys.prefix(keepRecent))
        let keysToRemove = sortedKeys.dropFirst(keepRecent)
        
        for key in keysToRemove {
            cachedMonths.removeValue(forKey: key)
        }
        
        print("🧹 StatsDataStore: 캐시 정리 완료")
        print("   - 제거: \(keysToRemove.count)개월")
        print("   - 유지: \(keysToKeep.joined(separator: ", "))")
    }
    
    /// 전체 캐시 초기화
    func clearAllCache() {
        let count = cachedMonths.count
        cachedMonths.removeAll()
        print("🗑️  StatsDataStore: 전체 캐시 초기화 (\(count)개월 제거)")
    }
    
    // MARK: - Private Methods
    
    /// 특정 월 데이터 로드 (Realm 우선 → 서버 폴백)
    private func loadMonth(for date: Date, silent: Bool = false) async -> [Post] {
        let monthKey = DateUtility.shared.monthKey(from: date)
        
        if !silent {
            loadingMonth = monthKey
        }
        
        defer {
            if !silent {
                loadingMonth = nil
            }
        }
        
        // ⭐ STEP 1: Realm 캐시 우선 확인
        let realmPosts = await realmManager.getPostsForMonth(monthKey)
        if !realmPosts.isEmpty {
            cachedMonths[monthKey] = realmPosts
            
            if !silent {
                print("💾 StatsDataStore: Realm 캐시 히트 - \(monthKey) (\(realmPosts.count)개)")
            } else {
                print("   💾 \(monthKey) - \(realmPosts.count)개 (Realm, 백그라운드)")
            }
            
            return realmPosts
        }
        
        // ⭐ STEP 2: Realm에 없으면 서버 호출 (폴백)
        do {
            guard let startOfMonth = DateUtility.shared.startOfMonth(for: date),
                  let endOfMonth = DateUtility.shared.endOfMonth(for: date) else {
                print("❌ StatsDataStore: 날짜 계산 실패 - \(monthKey)")
                return []
            }
            
            if !silent {
                print("🌐 StatsDataStore: 서버에서 로딩 - \(monthKey)")
            }
            
            let posts = try await postService.fetchPostsForDateRange(
                from: startOfMonth,
                to: endOfMonth
            )
            
            cachedMonths[monthKey] = posts
            
            if !silent {
                print("✅ StatsDataStore: 서버 로딩 완료 - \(monthKey) (\(posts.count)개)")
            } else {
                print("   ✅ \(monthKey) - \(posts.count)개 (서버, 백그라운드)")
            }
            
            // ⭐ 참고: DataStore가 이미 Realm에 저장하므로 여기서는 생략
            return posts
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ StatsDataStore: 로딩 실패 - \(monthKey)")
            print("   에러: \(error.localizedDescription)")
            
            // ⭐ STEP 3: 오프라인 상태 (Realm 없음 + 서버 실패)
            // 빈 배열 반환 = 진짜 데이터 없음
            return []
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
}
