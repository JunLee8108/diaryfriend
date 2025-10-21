//
//  StaticsView.swift
//  DiaryFriend
//

import SwiftUI

struct StaticsView: View {
    @EnvironmentObject var statsDataStore: StatsDataStore
    @State private var currentMonth = Date()
    @State private var monthPosts: [Post] = []
    @State private var isLoadingMonth = true
    
    // 최소 로딩 시간 (깜빡임 방지)
    private let minimumLoadingDuration: TimeInterval = 0.5
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    MonthSelectorHeader(
                        selectedMonth: $currentMonth,
                        isLoading: .constant(statsDataStore.isLoading),
                        onMonthChanged: handleMonthChange
                    )
                    
                    // ⭐ transition 제거 + id로 강제 재생성
                    if isLoadingMonth {
                        StatisticsLoadingView()
                            .id("loading")
                    } else if monthPosts.isEmpty {
                        StatisticsEmptyStateCard(month: currentMonth)
                            .id("empty-\(currentMonth.timeIntervalSince1970)")
                    } else {
                        statisticsContent
                            .id("content-\(monthPosts.count)-\(currentMonth.timeIntervalSince1970)")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 40)
            }
            .background(Color.modernBackground)
        }
        .task(id: currentMonth) {
            await loadCurrentMonth()
        }
    }
    
    // MARK: - Statistics Content
    
    @ViewBuilder
    private var statisticsContent: some View {
        Group {
            MonthOverviewCard(
                posts: monthPosts,
                selectedMonth: currentMonth
            )
            
            DetailedStatsCard(posts: monthPosts)
            
            MoodDistributionCard(posts: monthPosts)
            
            WritingPatternCalendar(
                posts: monthPosts,
                selectedMonth: currentMonth
            )
        }
    }
    
    // MARK: - Data Loading
    
    private func loadCurrentMonth() async {
        let monthKey = DateUtility.shared.monthKey(from: currentMonth)
        print("📊 StaticsView: \(monthKey) 로드 요청")
        
        // 캐시된 데이터 먼저 확인
        let cachedPosts = await statsDataStore.posts(for: currentMonth)
        let hasCache = !cachedPosts.isEmpty
        
        if hasCache {
            // 캐시가 있으면 즉시 표시 (스켈레톤 스킵)
            print("✅ StaticsView: \(monthKey) 캐시 사용 (스켈레톤 스킵)")
            monthPosts = cachedPosts
            isLoadingMonth = false
            
            // 백그라운드에서 조용히 최신화
            Task.detached(priority: .background) {
                await statsDataStore.prefetchAdjacent(to: currentMonth, range: 2)
            }
        } else {
            // 캐시가 없으면 로딩 상태 즉시 표시 (EmptyState 깜빡임 방지)
            print("⏳ StaticsView: \(monthKey) 캐시 없음 (스켈레톤 표시)")
            isLoadingMonth = true
            
            let startTime = Date()
            
            // 데이터 로드
            monthPosts = await statsDataStore.posts(for: currentMonth)
            
            // 경과 시간 계산
            let elapsedTime = Date().timeIntervalSince(startTime)
            let remainingTime = max(0, minimumLoadingDuration - elapsedTime)
            
            // 최소 로딩 시간 보장 (깜빡임 방지)
            if remainingTime > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
            }
            
            // ⭐ withAnimation 제거 - iOS 18 버그 방지
            isLoadingMonth = false
            
            // 백그라운드에서 인접 월 프리페치
            Task.detached(priority: .background) {
                await statsDataStore.prefetchAdjacent(to: currentMonth, range: 2)
            }
        }
    }
    
    private func handleMonthChange(_ newMonth: Date) async {
        let monthKey = DateUtility.shared.monthKey(from: newMonth)
        print("📅 StaticsView: 월 변경 → \(monthKey)")
    }
}
