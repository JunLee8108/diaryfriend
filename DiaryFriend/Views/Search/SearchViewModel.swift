//
//  SearchViewModel.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/9/25.
//

import Foundation
import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText = ""  // 입력 중인 텍스트 (실시간)
    @Published var activeQuery = ""  // 실제 검색된 쿼리 (Search 버튼 눌러야 변경)
    @Published var searchResults: [Post] = []
    @Published var isSearching = false
    @Published var resultSource: ResultSource = .none
    
    // MARK: - Private Properties
    private let dataStore = DataStore.shared
    private let realmManager = RealmManager.shared
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Result Source
    enum ResultSource {
        case none
        case memory(count: Int)
        case realm(count: Int)
        
        var showIndicator: Bool {
            if case .memory = self { return true }
            return false
        }
    }
    
    // MARK: - Search Methods
    
    /// 명시적 검색 실행 (Enter/Search 버튼 클릭 시)
    func performSearch() {
        // 이전 검색 취소
        searchTask?.cancel()
        
        let trimmedText = searchText.trimmingCharacters(in: .whitespaces)
        
        // 빈 검색어 처리
        guard !trimmedText.isEmpty else {
            activeQuery = ""
            searchResults = []
            resultSource = .none
            return
        }
        
        // ⭐ 핵심: activeQuery 업데이트 (이때부터 UI가 변경됨)
        activeQuery = trimmedText
        
        // 즉시 검색 실행
        searchTask = Task {
            await performHybridSearch()
        }
    }
    
    /// 하이브리드 검색 (메모리 → Realm)
    private func performHybridSearch() async {
        let startTime = Date()
        isSearching = true
        
        let query = activeQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Step 1: 메모리 캐시 검색 (즉시 - 최근 5개월)
        let memoryResults = searchInMemory(query: query)
        searchResults = memoryResults
        resultSource = .memory(count: memoryResults.count)
        
        let memoryDuration = Date().timeIntervalSince(startTime)
        print("🔍 Memory search: \(memoryResults.count) results in \(String(format: "%.0f", memoryDuration * 1000))ms")
        
        // Step 2: Realm 검색 (백그라운드 - 전체 데이터)
        if !Task.isCancelled {
            let realmStartTime = Date()
            let realmResults = await searchInRealm(query: query)
            
            let realmDuration = Date().timeIntervalSince(realmStartTime)
            print("🔍 Realm search: \(realmResults.count) results in \(String(format: "%.0f", realmDuration * 1000))ms")
            
            // 더 많은 결과가 있으면 교체
            if realmResults.count > memoryResults.count {
                searchResults = realmResults
                resultSource = .realm(count: realmResults.count)
                
                // 햅틱 피드백 (추가 결과 발견)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                print("✅ Updated to Realm results (+\(realmResults.count - memoryResults.count) more)")
            }
        }
        
        isSearching = false
        let totalDuration = Date().timeIntervalSince(startTime)
        print("🎯 Total search time: \(String(format: "%.0f", totalDuration * 1000))ms")
    }
    
    /// 메모리 캐시에서 검색 (DataStore.posts - 최근 5개월)
    private func searchInMemory(query: String) -> [Post] {
        dataStore.posts.filter { post in
            // 1. 컨텐츠 검색 (plainContent)
            post.plainContent.localizedCaseInsensitiveContains(query) ||
            
            // 2. 무드 검색
            (post.mood?.localizedCaseInsensitiveContains(query) ?? false) ||
            
            // 3. 날짜 검색 (YYYY-MM-DD)
            post.entry_date.contains(query)
        }
        .sorted { $0.entry_date > $1.entry_date }
    }
    
    /// Realm에서 검색 (전체 로컬 DB)
    private func searchInRealm(query: String) async -> [Post] {
        await realmManager.searchPosts(query: query)
    }
    
    /// 검색 초기화
    func clearSearch() {
        searchTask?.cancel()
        searchText = ""
        activeQuery = ""
        searchResults = []
        resultSource = .none
        isSearching = false
    }
}
