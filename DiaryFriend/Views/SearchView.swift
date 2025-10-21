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
                
                // Result Source Indicator
                if viewModel.resultSource.showIndicator {
                    HStack {
                        if viewModel.isSearching {
                            ProgressView()
                                .scaleEffect(0.7)
                                .padding(.leading, 4)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Results Area - ⭐ activeQuery 기준으로 판단
                ScrollView {
                    if viewModel.activeQuery.isEmpty {
                        // 검색 실행 전 (타이핑 중이어도 이 화면 유지)
                        EmptySearchView()
                    } else if viewModel.searchResults.isEmpty && !viewModel.isSearching {
                        // 검색 실행했지만 결과 없음
                        NoResultsView(query: viewModel.activeQuery)
                    } else {
                        // 검색 결과 있음
                        SearchResultsSection(
                            posts: viewModel.searchResults,
                            searchQuery: viewModel.activeQuery
                        )
                        .padding(.top, 8)
                    }
                }
                .onTapGesture {
                    isSearchFocused = false
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 20)
                }
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
        .animation(.easeInOut(duration: 0.2), value: viewModel.resultSource.showIndicator)
    }
}

#Preview {
    SearchView()
        .environmentObject(DataStore.shared)
}
