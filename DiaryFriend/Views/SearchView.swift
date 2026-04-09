//
//  SearchView.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/9/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @EnvironmentObject var dataStore: DataStore
    
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.path) {
            VStack(spacing: 0) {
                // Search Input Bar
                SearchInputBar(
                    text: $viewModel.searchText,
                    isSearching: viewModel.isSearching,
                    onClear: {
                        viewModel.clearSearch()
                    },
                    onSearch: {
                        viewModel.performSearch()
                    }
                )
                .focused($isSearchFocused)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // ⭐ ZStack으로 변경 - 부드러운 크로스페이드
                ZStack {
                    // 검색 전 상태
                    if viewModel.activeQuery.isEmpty {
                        EmptySearchView()
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    // 검색 결과 없음
                    if !viewModel.activeQuery.isEmpty &&
                       viewModel.searchResults.isEmpty &&
                       !viewModel.isSearching {
                        NoResultsView(query: viewModel.activeQuery)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    // 검색 결과 있음
                    if !viewModel.searchResults.isEmpty {
                        ScrollView {
                            SearchResultsSection(
                                posts: viewModel.searchResults,
                                searchQuery: viewModel.activeQuery
                            )
                            .padding(.top, 8)
                            
                            Color.clear.frame(height: 20)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.activeQuery)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.searchResults.isEmpty)
            }
            .background(Color.modernBackground)
            .onTapGesture {
                isSearchFocused = false
            }
            .navigationDestination(for: PostDestination.self) { destination in
                if case .detail(let postId) = destination {
                    PostDetailView(postId: postId)
                        .environmentObject(navigationCoordinator)
                }
            }
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(DataStore.shared)
}
