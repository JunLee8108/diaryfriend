////
////  DataStore.swift
////  DiaryFriend
////
////  메모리 기반 데이터 캐싱 및 관리
////  5개월 윈도우 정책으로 효율적인 데이터 로딩
////  NSCache를 사용한 PostDetail 자동 메모리 관리
////

import Foundation
import SwiftUI

// MARK: - PostDetail Wrapper for NSCache
class PostDetailWrapper: NSObject {
    let detail: PostDetail
    let timestamp: Date
    
    init(_ detail: PostDetail) {
        self.detail = detail
        self.timestamp = Date()
        super.init()
    }
}

@MainActor
class DataStore: ObservableObject {
    // MARK: - Singleton
    static let shared = DataStore()
    
    private init() {
        setupCache()
        Logger.debug("✅ Post Detail NSCache 설정 완료")
    }
    
    // MARK: - Published Properties
    @Published private(set) var posts: [Post] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var updatedPostDetailId: Int?
    @Published private(set) var syncProgress: Double = 0.0  // 0.0 ~ 1.0
    @Published private(set) var syncingMonth: String?
    @Published private(set) var lastSyncDate: Date?
    
    // MARK: - Private Properties
    private let postService = PostService()
    private let realmManager = RealmManager.shared
    private var loadedMonths: Set<String> = []  // "2025-01" 형식
    private var isInitialized = false
    private var pollingPostIds: Set<Int> = []
    
    // NSCache for PostDetail (자동 메모리 관리)
    private let postDetailCache = NSCache<NSNumber, PostDetailWrapper>()
    
    // 캐시 통계 (디버깅용)
    private var cacheHits = 0
    private var cacheMisses = 0
    
    // MARK: - Cache Setup
    private func setupCache() {
        // 캐시 제한 설정
        postDetailCache.countLimit = 30  // 최대 30개
        postDetailCache.totalCostLimit = 10_000_000  // 10MB
        postDetailCache.name = "PostDetailCache"
        
        // 메모리 경고 옵저버
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // 백그라운드 진입 시 캐시 정리
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        Logger.debug("📦 NSCache 설정: 최대 30개, 10MB 제한")
    }
    
    @objc private func handleMemoryWarning() {
        print("⚠️ 메모리 경고! NSCache가 자동으로 정리합니다")
        print("   - 현재 캐시 통계: Hits=\(cacheHits), Misses=\(cacheMisses)")
        // NSCache는 자동으로 항목을 제거하므로 추가 작업 불필요
    }
    
    @objc private func handleEnterBackground() {
        print("📱 앱이 백그라운드로 전환 - 캐시 일부 정리")
        // 선택적으로 일부 캐시 정리 가능
    }
    
    // MARK: - Cache Cost Calculation
    private func calculateCost(for detail: PostDetail) -> Int {
        let contentCost = detail.content.count * 2  // 문자당 2바이트
        let commentCost = (detail.Comment?.count ?? 0) * 500  // 댓글당 500바이트
        let imageCost = (detail.Image?.count ?? 0) * 2000  // 이미지 정보당 2KB
        let hashtagCost = (detail.Post_Hashtag?.count ?? 0) * 100  // 해시태그당 100바이트
        let totalCost = contentCost + commentCost + imageCost + hashtagCost + 1000  // 기본 1KB
        
        print("💰 Cost 계산: Content=\(contentCost), Comments=\(commentCost), Images=\(imageCost), Total=\(totalCost)")
        return totalCost
    }
    
    // MARK: - Computed Properties (메모리에서 계산)
    
    /// 최근 포스트 N개 (날짜당 최신 1개만)
    func recentPosts(limit: Int = 3) -> [Post] {
        let groupedByDate = Dictionary(grouping: posts) { $0.entry_date }
        
        let latestPostPerDay = groupedByDate.compactMap { (date, postsOnDate) -> Post? in
            return postsOnDate.sorted { $0.created_at > $1.created_at }.first
        }
        
        return Array(
            latestPostPerDay
                .sorted { $0.entry_date > $1.entry_date }
                .prefix(limit)
        )
    }
    
    /// 특정 날짜의 포스트들
    func posts(for date: String) -> [Post] {
        posts.filter { $0.entry_date == date }
            .sorted { $0.created_at > $1.created_at }
    }
    
    /// 특정 날짜의 포스트 개수
    func postCount(for date: String) -> Int {
        posts.filter { $0.entry_date == date }.count
    }
    
    /// 특정 년월의 포스트들
    func posts(for year: Int, month: Int) -> [Post] {
        let monthString = String(format: "%04d-%02d", year, month)
        return posts.filter { $0.entry_date.hasPrefix(monthString) }
            .sorted { $0.entry_date > $1.entry_date }
    }
    
    /// 포스트가 있는 날짜 Set (캘린더 표시용)
    var postDates: Set<String> {
        Set(posts.map { $0.entry_date })
    }
    
    /// 현재 월의 포스트 개수
    var currentMonthPostCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        return posts(for: year, month: month).count
    }
    
    /// 전체 포스트 개수 (메모리 기준)
    var totalPostCount: Int {
        posts.count
    }
    
    /// 캐시 통계 정보 (디버깅용)
    var cacheStatistics: String {
        let hitRate = cacheMisses > 0 ? Double(cacheHits) / Double(cacheHits + cacheMisses) * 100 : 0
        return "Cache Stats - Hits: \(cacheHits), Misses: \(cacheMisses), Hit Rate: \(String(format: "%.1f", hitRate))%"
    }
    
    // MARK: - Public Methods
    
    /// 초기 데이터 로드 (앱 시작시 1회)
    func initialLoad() async {
        guard !isInitialized else {
            print("📊 DataStore: 이미 초기화됨")
            return
        }
        
        await loadFiveMonthWindow(centerDate: Date())
        isInitialized = true
    }
    
    /// 5개월 윈도우 로드 (현재 + 이전/다음 2개월)
    private func loadFiveMonthWindow(centerDate: Date) async {
        isLoading = true
        errorMessage = nil
        
        let calendar = Calendar.current
        let monthsToLoad = [
            calendar.date(byAdding: .month, value: -2, to: centerDate)!,
            calendar.date(byAdding: .month, value: -1, to: centerDate)!,
            centerDate,
            calendar.date(byAdding: .month, value: 1, to: centerDate)!,
            calendar.date(byAdding: .month, value: 2, to: centerDate)!
        ]
        
        print("📊 DataStore: 5개월 윈도우 로딩 시작")
        
        for date in monthsToLoad {
            await loadMonth(for: date)
        }
        
        isLoading = false
        print("✅ DataStore: 로드 완료 (총 \(posts.count)개 포스트)")
    }
    
    func ensureMonthLoaded(_ date: Date) async {
        // 즉시 정리
        cleanupPostsOutsideWindow(centerDate: date)
        
        // 백그라운드 보충
        Task.detached { [weak self] in
            await self?.loadMissingMonthsInWindow(centerDate: date)
        }
        
        print("📅 현재 로드된 월: \(loadedMonths)")
    }
    
    private func loadMissingMonthsInWindow(centerDate: Date) async {
        let calendar = Calendar.current
        
        let monthsNeeded = [
            calendar.date(byAdding: .month, value: -2, to: centerDate)!,
            calendar.date(byAdding: .month, value: -1, to: centerDate)!,
            centerDate,
            calendar.date(byAdding: .month, value: 1, to: centerDate)!,
            calendar.date(byAdding: .month, value: 2, to: centerDate)!
        ]
        
        let missingMonths = monthsNeeded.filter { month in
            let key = DateUtility.shared.monthKey(from: month)
            return !loadedMonths.contains(key)
        }
        
        guard !missingMonths.isEmpty else { return }
        
        for month in missingMonths {
            await loadMonth(for: month, silent: true)
        }
    }
    
    /// 수동 새로고침 (Pull-to-refresh)
    func refresh(centerDate: Date = Date()) async {
        print("🔄 DataStore: Diff 기반 새로고침 시작 (기준: \(DateUtility.shared.monthKey(from: centerDate)))")
        print("🗑️ PostDetail 캐시 초기화")
        
        // 1. NSCache 초기화
        postDetailCache.removeAllObjects()
        cacheHits = 0
        cacheMisses = 0
        
        let calendar = Calendar.current
        
        // 2. 5개월 범위 계산 (±2개월)
        let monthsToRefresh = [
            calendar.date(byAdding: .month, value: -2, to: centerDate)!,
            calendar.date(byAdding: .month, value: -1, to: centerDate)!,
            centerDate,
            calendar.date(byAdding: .month, value: 1, to: centerDate)!,
            calendar.date(byAdding: .month, value: 2, to: centerDate)!
        ]
        
        let refreshKeys = monthsToRefresh.map { DateUtility.shared.monthKey(from: $0) }
        
        print("📅 동기화 대상: \(refreshKeys.joined(separator: ", "))")
        
        isLoading = true
        errorMessage = nil
        syncProgress = 0.0
        
        let task = Task { @MainActor in
            // 3. Diff 기반 동기화 수행
            await syncMonthsWithServer(months: monthsToRefresh, monthKeys: refreshKeys)
            
            // 4. 정렬
            self.posts.sort { $0.entry_date > $1.entry_date }
            
            // 5. 완료 처리
            self.isLoading = false
            self.syncProgress = 1.0
            self.lastSyncDate = Date()
            self.syncingMonth = nil
            
            print("✅ DataStore: Diff 기반 새로고침 완료 (총 \(self.posts.count)개)")
            print("📊 \(self.cacheStatistics)")
        }
        
        _ = await task.value
    }
    
    // DataStore.swift

    /// 여러 월을 서버와 동기화 (Diff 기반)
    private func syncMonthsWithServer(months: [Date], monthKeys: [String]) async {
        var successCount = 0
        var failedMonths: [String] = []
        var totalDeleted = 0
        var totalAdded = 0
        var totalUpdated = 0
        
        print("🔄 \(months.count)개월 동기화 시작...")
        
        for (index, date) in months.enumerated() {
            let monthKey = monthKeys[index]
            
            // 진행률 업데이트
            await MainActor.run {
                self.syncProgress = Double(index) / Double(months.count)
                self.syncingMonth = monthKey
            }
            
            do {
                let metrics = try await syncSingleMonth(date: date, monthKey: monthKey)
                
                successCount += 1
                totalDeleted += metrics.deleted
                totalAdded += metrics.added
                totalUpdated += metrics.updated
                
                print("✅ \(monthKey) 동기화 성공 (삭제: \(metrics.deleted), 추가: \(metrics.added), 업데이트: \(metrics.updated))")
                
            } catch let error as SyncError {
                failedMonths.append(monthKey)
                print("⚠️ \(monthKey) 동기화 실패: \(error.localizedDescription)")
                
                await recoverFromRealmForMonth(monthKey)
                
            } catch {
                failedMonths.append(monthKey)
                print("❌ \(monthKey) 동기화 중 예상치 못한 오류: \(error.localizedDescription)")
                
                await recoverFromRealmForMonth(monthKey)
            }
        }
        
        // 최종 결과 로깅
        print("\n📊 동기화 최종 결과:")
        print("   성공: \(successCount)/\(months.count) 개월")
        print("   전체 삭제: \(totalDeleted)개")
        print("   전체 추가: \(totalAdded)개")
        print("   전체 업데이트: \(totalUpdated)개")
        
        if !failedMonths.isEmpty {
            let errorMsg = "일부 데이터 동기화 실패: \(failedMonths.joined(separator: ", "))"
            print("⚠️ \(errorMsg)")
            
            await MainActor.run {
                self.errorMessage = errorMsg
            }
        }
    }
    
    // DataStore.swift

    /// 단일 월을 서버와 동기화 (Diff 기반 + PostChangeNotification)
    private func syncSingleMonth(date: Date, monthKey: String) async throws -> SyncMetrics {
        print("\n🔍 [\(monthKey)] 동기화 시작...")
        
        // Step 1: 날짜 범위 계산
        guard let startOfMonth = DateUtility.shared.startOfMonth(for: date),
              let endOfMonth = DateUtility.shared.endOfMonth(for: date) else {
            print("❌ [\(monthKey)] 날짜 계산 실패")
            throw SyncError.dateCalculationFailed
        }
        
        // Step 2: 서버에서 데이터 가져오기
        let serverPosts: [Post]
        do {
            serverPosts = try await postService.fetchPostsForDateRange(
                from: startOfMonth,
                to: endOfMonth
            )
            print("📥 [\(monthKey)] 서버: \(serverPosts.count)개 포스트")
        } catch {
            print("❌ [\(monthKey)] 서버 조회 실패: \(error.localizedDescription)")
            throw SyncError.networkFailure(monthKey, error.localizedDescription)
        }
        
        // Step 3: Realm에서 현재 데이터 가져오기
        let realmPosts = await realmManager.getPostsForMonth(monthKey)
        print("💾 [\(monthKey)] Realm: \(realmPosts.count)개 포스트")
        
        // Step 4: ID 세트 생성
        let serverPostIds = Set(serverPosts.map { $0.id })
        let realmPostIds = Set(realmPosts.map { $0.id })
        
        // Step 5: Diff 계산
        let postsToDelete = realmPostIds.subtracting(serverPostIds)  // Realm에만 있음 → 삭제됨
        let postsToAdd = serverPostIds.subtracting(realmPostIds)     // 서버에만 있음 → 새로 생성됨
        let postsToUpdate = serverPostIds.intersection(realmPostIds) // 둘 다 있음 → 업데이트 필요
        
        print("📊 [\(monthKey)] Diff 결과:")
        print("   🗑️  삭제: \(postsToDelete.count)개 - IDs: \(Array(postsToDelete).sorted())")
        print("   ➕ 추가: \(postsToAdd.count)개 - IDs: \(Array(postsToAdd).sorted())")
        print("   🔄 업데이트: \(postsToUpdate.count)개")
        
        // Step 6: Realm 동기화
        do {
            // 6-1. 삭제 작업
            if !postsToDelete.isEmpty {
                try await realmManager.deletePosts(ids: Array(postsToDelete))
                print("✅ [\(monthKey)] Realm에서 \(postsToDelete.count)개 삭제 완료")
            }
            
            // 6-2. 추가/업데이트 작업 (savePosts는 upsert 방식)
            if !serverPosts.isEmpty {
                try await realmManager.savePosts(serverPosts)
                print("✅ [\(monthKey)] Realm에 \(serverPosts.count)개 저장 완료")
            }
            
        } catch {
            print("❌ [\(monthKey)] Realm 동기화 실패: \(error.localizedDescription)")
            throw SyncError.realmFailure(monthKey, error.localizedDescription)
        }
        
        // Step 7: 메모리 동기화 + ⭐ PostChangeNotification 발송
        await MainActor.run {
            // 7-1. 삭제 처리
            if !postsToDelete.isEmpty {
                let beforeCount = self.posts.count
                self.posts.removeAll { postsToDelete.contains($0.id) }
                let actualDeleted = beforeCount - self.posts.count
                print("🧹 [\(monthKey)] 메모리에서 \(actualDeleted)개 제거")
                
                // ⭐ 삭제 이벤트 발송
                for postId in postsToDelete {
                    // 삭제된 포스트의 날짜 정보 찾기
                    if let deletedPost = realmPosts.first(where: { $0.id == postId }) {
                        PostChangeManager.shared.notifyPostDeleted(
                            postId: postId,
                            date: deletedPost.entry_date
                        )
                        print("   📢 Delete 이벤트 발송: Post \(postId) (\(deletedPost.entry_date))")
                    }
                }
            }
            
            // 7-2. 추가/업데이트 처리
            var addedCount = 0
            var updatedCount = 0
            
            for serverPost in serverPosts {
                if let index = self.posts.firstIndex(where: { $0.id == serverPost.id }) {
                    // 업데이트
                    self.posts[index] = serverPost
                    updatedCount += 1
                    
                    // ⭐ 업데이트 이벤트 발송
                    PostChangeManager.shared.notifyPostUpdated(
                        postId: serverPost.id,
                        date: serverPost.entry_date
                    )
                    print("   📢 Update 이벤트 발송: Post \(serverPost.id) (\(serverPost.entry_date))")
                    
                } else {
                    // 추가
                    self.posts.append(serverPost)
                    addedCount += 1
                    
                    // ⭐ 추가 이벤트 발송
                    PostChangeManager.shared.notifyPostCreated(
                        postId: serverPost.id,
                        date: serverPost.entry_date
                    )
                    print("   📢 Create 이벤트 발송: Post \(serverPost.id) (\(serverPost.entry_date))")
                }
            }
            
            print("➕ [\(monthKey)] 추가: \(addedCount)개")
            print("🔄 [\(monthKey)] 업데이트: \(updatedCount)개")
            
            // 7-3. 로드된 월 상태 업데이트
            self.loadedMonths.insert(monthKey)
        }
        
        print("✅ [\(monthKey)] 메모리 동기화 완료 (현재 총 \(posts.count)개)")
        
        // Step 8: 메트릭 반환
        return SyncMetrics(
            deleted: postsToDelete.count,
            added: postsToAdd.count,
            updated: postsToUpdate.count
        )
    }

    /// Realm 데이터로 메모리 복구
    private func recoverFromRealmForMonth(_ monthKey: String) async {
        print("💾 [\(monthKey)] Realm 데이터로 복구 시도...")
        
        let realmPosts = await realmManager.getPostsForMonth(monthKey)
        
        await MainActor.run {
            // 메모리에 없는 Realm 포스트만 추가
            for post in realmPosts {
                if !self.posts.contains(where: { $0.id == post.id }) {
                    self.posts.append(post)
                }
            }
            
            self.loadedMonths.insert(monthKey)
        }
        
        print("✅ [\(monthKey)] Realm에서 \(realmPosts.count)개 복구 완료")
    }
    
    // MARK: - Post Detail Operations (NSCache 적용)
    
    /// 포스트 상세 정보 가져오기
    func getPostDetail(id: Int) async -> PostDetail? {
        let cacheKey = NSNumber(value: id)
        
        // 1. NSCache 확인
        if let wrapper = postDetailCache.object(forKey: cacheKey) {
            cacheHits += 1
            print("🎯 NSCache HIT: ID \(id) (총 Hits: \(cacheHits))")
            print("   - 캐시된 시간: \(wrapper.timestamp)")
            
            // pending 상태 + 폴링 중이 아닐 때만 시작
            if wrapper.detail.ai_processing_status == "pending" && !pollingPostIds.contains(id) {
                pollingPostIds.insert(id)
                Task.detached { [weak self] in
                    await self?.pollUntilAICompleted(id: id)
                }
            }
            
            return wrapper.detail
        }
        
        cacheMisses += 1
        print("❌ NSCache MISS: ID \(id) (총 Misses: \(cacheMisses))")
        
        // 2. Realm 캐시 확인
        if let realmCached = await realmManager.getPostDetail(id: id) {
            print("💾 PostDetail Realm 캐시 히트: ID \(id)")
            
            // NSCache에 저장
            let wrapper = PostDetailWrapper(realmCached)
            let cost = calculateCost(for: realmCached)
            postDetailCache.setObject(wrapper, forKey: cacheKey, cost: cost)
            print("➕ NSCache에 추가: ID \(id), Cost: \(cost) bytes")
            
            return realmCached
        }
        
        // 3. 서버에서 가져오기
        do {
            let detail = try await postService.fetchPostDetail(id: id)
            
            // NSCache에 저장
            let wrapper = PostDetailWrapper(detail)
            let cost = calculateCost(for: detail)
            postDetailCache.setObject(wrapper, forKey: cacheKey, cost: cost)
            print("➕ NSCache에 추가: ID \(id), Cost: \(cost) bytes")
            
            if detail.ai_processing_status != "pending" {
                try? await realmManager.savePostDetail(detail)
                print("✅ PostDetail Realm 저장 완료: ID \(id)")
            } else {
                // 폴링 중이 아닐 때만 시작
                if !pollingPostIds.contains(id) {
                    print("⏳ AI 처리 대기 중... 폴링 시작")
                    pollingPostIds.insert(id)
                    Task.detached { [weak self] in
                        await self?.pollUntilAICompleted(id: id)
                    }
                }
            }
            
            print("🌐 PostDetail 서버에서 로드: ID \(id)")
            print("📊 현재 캐시 통계: \(cacheStatistics)")
            return detail
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ PostDetail 로드 실패: \(error)")
            return nil
        }
    }
    
    /// AI 처리 완료까지 폴링
    private func pollUntilAICompleted(id: Int, maxAttempts: Int = 10) async {
        let cacheKey = NSNumber(value: id)
        
        for attempt in 1...maxAttempts {
            try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2초 대기
            
            do {
                let detail = try await postService.fetchPostDetail(id: id)
                
                await MainActor.run {
                    // NSCache 업데이트
                    let wrapper = PostDetailWrapper(detail)
                    let cost = self.calculateCost(for: detail)
                    self.postDetailCache.setObject(wrapper, forKey: cacheKey, cost: cost)
                    self.updatedPostDetailId = id
                    print("🔄 NSCache 업데이트 (폴링): ID \(id), Cost: \(cost)")
                }
                
                if detail.ai_processing_status != "pending" {
                    try? await realmManager.savePostDetail(detail)
                    print("✅ AI 처리 완료 감지 (시도 \(attempt)/\(maxAttempts))")
                    print("   - 댓글: \(detail.Comment?.count ?? 0)개")
                    break
                }
                
                print("⏳ AI 처리 대기 중... (\(attempt)/\(maxAttempts))")
                
            } catch {
                print("⚠️ 폴링 중 오류: \(error)")
                break
            }
        }
        
        await MainActor.run {
            self.pollingPostIds.remove(id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updatedPostDetailId = nil
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    /// 새 포스트 생성
    func createPost(
        content: String,
        mood: String?,
        hashtags: [String] = [],
        entryDate: Date? = nil,
        characterId: Int? = nil,
        allowAIComments: Bool = true,
        images: [(path: String, size: Int)] = [],
        aiGenerated: Bool = false
    ) async throws -> Post {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. PostService 호출
            let newPost = try await postService.createPost(
                content: content,
                mood: mood,
                hashtags: hashtags,
                entryDate: entryDate,
                characterId: characterId,
                allowAIComments: allowAIComments,
                aiGenerated: aiGenerated
            )
            
            // 2. 이미지 레코드 생성
            if !images.isEmpty {
                try await ImageService.shared.createImageRecords(
                    postId: newPost.id,
                    storagePaths: images
                )
                print("✅ Created \(images.count) image records for Post \(newPost.id)")
            }
            
            // 3. 메모리 캐시에 즉시 추가
            posts.append(newPost)
            posts.sort { $0.entry_date > $1.entry_date }
            
            // 4. Realm에도 저장
            try? await realmManager.savePosts([newPost])
            
            // 5. 월 로드 상태 업데이트
            let monthKey = String(newPost.entry_date.prefix(7))
            loadedMonths.insert(monthKey)
            
            // 6. AI Processing (백그라운드)
            if allowAIComments {
                Task.detached {
                    try? await SupabaseManager.shared.triggerAIProcessing(
                        postId: newPost.id,
                        content: content,
                        hashtags: hashtags,
                        mood: mood
                    )
                }
            }
            
            PostChangeManager.shared.notifyPostCreated(
                postId: newPost.id,
                date: newPost.entry_date
            )
            
            print("➕ DataStore: 새 포스트 추가됨 (ID: \(newPost.id))")
            return newPost
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Post 업데이트 (content, mood, hashtags, images)
    func updatePost(
        id: Int,
        content: String?,
        mood: String?,
        hashtags: [String]?,
        newImages: [UIImage]?,
        imagesToDelete: [String]?
    ) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. 이미지 삭제
            if let deleteIds = imagesToDelete, !deleteIds.isEmpty {
                try await ImageService.shared.deleteImages(ids: deleteIds)
            }
            
            // 2. 새 이미지 업로드
            if let images = newImages, !images.isEmpty {
                let currentImages = try await ImageService.shared.fetchImages(forPostId: id)
                let remainingCount = currentImages.count - (imagesToDelete?.count ?? 0)
                let availableSlots = max(0, 3 - remainingCount)
                
                var uploadedImageInfo: [(path: String, size: Int)] = []
                for (index, image) in images.prefix(availableSlots).enumerated() {
                    let path = try await ImageService.shared.uploadImage(
                        image,
                        order: remainingCount + index
                    )
                    let size = image.jpegData(compressionQuality: 0.8)?.count ?? 0
                    uploadedImageInfo.append((path: path, size: size))
                }
                
                if !uploadedImageInfo.isEmpty {
                    try await ImageService.shared.createImageRecords(
                        postId: id,
                        storagePaths: uploadedImageInfo
                    )
                }
            }
            
            // 3. Post 업데이트
            let updatedPost = try await postService.updatePost(
                id: id,
                content: content,
                mood: mood,
                hashtags: hashtags
            )
            
            // 4. 메모리 캐시 업데이트
            if let index = posts.firstIndex(where: { $0.id == id }) {
                posts[index] = updatedPost
            }
            
            // 5. Realm 무효화
            try? await realmManager.deletePost(id: id)
            
            // 6. PostDetail NSCache 무효화
            let cacheKey = NSNumber(value: id)
            postDetailCache.removeObject(forKey: cacheKey)
            print("🗑️ NSCache에서 제거: ID \(id)")
            
            // 7. 업데이트 완료 신호 발행
            updatedPostDetailId = id
            
            PostChangeManager.shared.notifyPostUpdated(
                postId: id,
                date: updatedPost.entry_date
            )
            
            print("✅ Post \(id) 업데이트 완료")
            print("📊 현재 캐시 통계: \(cacheStatistics)")
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// 포스트 삭제
    func deletePost(id: Int, date: Date, aiGenerated: Bool) async throws {
        do {
            try await postService.deletePost(id: id)
            
            if aiGenerated {
                try await ChatService.shared.handlePostDeletion(
                    postId: id,
                    date: date
                )
            }
            
            // ⭐ 파라미터로 받은 date 사용
            let dateString = DateUtility.shared.dateString(from: date)
            
            posts.removeAll { $0.id == id }
            
            let cacheKey = NSNumber(value: id)
            postDetailCache.removeObject(forKey: cacheKey)
            
            try? await realmManager.deletePost(id: id)
            
            // ⭐ 변환한 dateString 사용
            PostChangeManager.shared.notifyPostDeleted(
                postId: id,
                date: dateString
            )
            
            print("✅ Post \(id) 삭제 완료")
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// 특정 월 데이터 로드 (3단계 캐싱)
    private func loadMonth(for date: Date, forceRefresh: Bool = false, silent: Bool = false) async {
        let monthKey = DateUtility.shared.monthKey(from: date)
        
        // 이미 로드된 월은 스킵 (강제 새로고침 아닌 경우)
        guard forceRefresh || !loadedMonths.contains(monthKey) else {
            print("⭐️ DataStore: \(monthKey) 이미 로드됨")
            return
        }
        
        do {
            guard let startOfMonth = DateUtility.shared.startOfMonth(for: date),
                  let endOfMonth = DateUtility.shared.endOfMonth(for: date) else {
                return
            }
            
            let startString = DateUtility.shared.dateString(from: startOfMonth)
            let endString = DateUtility.shared.dateString(from: endOfMonth)
            
            print("🔥 DataStore: \(monthKey) 로딩 중...")
            
            var monthPosts: [Post] = []
            
            // 1. Realm에서 먼저 확인 (강제 새로고침이 아닌 경우)
            if !forceRefresh {
                let realmPosts = await realmManager.getPostsForDateRange(
                    from: startString,
                    to: endString
                )
                
                if !realmPosts.isEmpty {
                    monthPosts = realmPosts
                    print("💾 DataStore: \(monthKey) Realm에서 \(realmPosts.count)개 로드")
                }
            }
            
            // 2. Realm이 비어있거나 강제 새로고침인 경우 서버에서 로드
            if monthPosts.isEmpty || forceRefresh {
                monthPosts = try await postService.fetchPostsForDateRange(
                    from: startOfMonth,
                    to: endOfMonth
                )
                
                // Realm에 저장
                if !monthPosts.isEmpty {
                    try? await realmManager.savePosts(monthPosts)
                }
                
                print("🌐 DataStore: \(monthKey) 서버에서 \(monthPosts.count)개 로드")
            }
            
            // 3. 메모리에 추가 (중복 체크)
            for post in monthPosts {
                if !posts.contains(where: { $0.id == post.id }) {
                    posts.append(post)
                }
            }
            
            posts.sort { $0.entry_date > $1.entry_date }
            loadedMonths.insert(monthKey)
            
            print("✅ DataStore: \(monthKey) 로드 완료")
            
        } catch {
            errorMessage = "데이터 로드 실패: \(error.localizedDescription)"
            print("❌ DataStore: \(monthKey) 로드 실패 - \(error)")
        }
    }
    
    // MARK: - Memory Management
    
    private func cleanupPostsOutsideWindow(centerDate: Date) {
        let calendar = Calendar.current
        
        // ±2개월 = 5개월 윈도우
        guard let windowStart = calendar.date(byAdding: .month, value: -2, to: centerDate),
              let windowEnd = calendar.date(byAdding: .month, value: 2, to: centerDate) else {
            return
        }
        
        let startKey = DateUtility.shared.monthKey(from: windowStart)
        let endKey = DateUtility.shared.monthKey(from: windowEnd)
        
        let beforeCount = posts.count
        
        posts = posts.filter { post in
            let postMonth = String(post.entry_date.prefix(7))
            return postMonth >= startKey && postMonth <= endKey
        }
        
        loadedMonths = loadedMonths.filter { month in
            month >= startKey && month <= endKey
        }
        
        let removed = beforeCount - posts.count
        if removed > 0 {
            print("🧹 메모리 정리: \(removed)개 posts 제거")
            print("   - 유지 범위: \(startKey) ~ \(endKey) (5개월)")
            print("   - 현재 메모리: \(posts.count)개 posts")
        }
    }
    
    /// 메모리 정리 (12개월 이상 오래된 데이터 제거)
    func cleanupOldData(keepMonths: Int = 12) {
        guard let cutoffDate = DateUtility.shared.date(byAddingMonths: -keepMonths, to: Date()) else {
            return
        }
        
        let cutoffKey = DateUtility.shared.monthKey(from: cutoffDate)
        
        // 오래된 월 제거
        let oldMonths = loadedMonths.filter { $0 < cutoffKey }
        for month in oldMonths {
            loadedMonths.remove(month)
        }
        
        // 오래된 포스트 제거
        let oldCount = posts.count
        posts = posts.filter { post in
            post.entry_date >= cutoffKey + "-01"
        }
        
        let removed = oldCount - posts.count
        if removed > 0 {
            print("🧹 DataStore: \(removed)개 오래된 포스트 정리됨")
        }
        
        // Realm 정리도 함께
        Task {
            try? await realmManager.cleanupOldPosts(olderThan: keepMonths * 30)
        }
    }
    
    func clearAllData() async {
        // 메모리 캐시 초기화
        posts.removeAll()
        loadedMonths.removeAll()
        
        // NSCache 초기화
        postDetailCache.removeAllObjects()
        print("🗑️ NSCache 전체 초기화")
        
        // 통계 리셋
        cacheHits = 0
        cacheMisses = 0
        
        isInitialized = false
        errorMessage = nil
        
        // Realm 초기화
        do {
            try await realmManager.clearAllPosts()
            print("🧹 DataStore: 모든 데이터 초기화 완료")
        } catch {
            print("❌ DataStore 초기화 실패: \(error)")
        }
    }
    
    // 사용자 변경 시 재초기화
    func resetForNewUser() async {
        await clearAllData()
        isInitialized = false
        print("👤 새 사용자를 위한 DataStore 리셋 완료")
    }
}

// MARK: - Supporting Types

/// 동기화 메트릭
struct SyncMetrics {
    let deleted: Int
    let added: Int
    let updated: Int
}

/// 동기화 에러
enum SyncError: LocalizedError {
    case dateCalculationFailed
    case networkFailure(String, String)  // (monthKey, message)
    case realmFailure(String, String)     // (monthKey, message)
    
    var errorDescription: String? {
        switch self {
        case .dateCalculationFailed:
            return "날짜 계산 실패"
        case .networkFailure(let month, let message):
            return "[\(month)] 네트워크 오류: \(message)"
        case .realmFailure(let month, let message):
            return "[\(month)] 데이터베이스 오류: \(message)"
        }
    }
}
