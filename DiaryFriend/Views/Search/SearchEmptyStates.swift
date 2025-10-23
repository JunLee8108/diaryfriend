//
//  SearchEmptyStates.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/9/25.
//

import SwiftUI

// MARK: - 검색 시작 전
struct EmptySearchView: View {
    @Localized(.search_empty_title) var title
    @Localized(.search_empty_description) var description
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "00C896").opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "00C896"))
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}

// MARK: - 결과 없음
struct NoResultsView: View {
    let query: String
    
    @Localized(.search_no_results) var noResultsText
    @Localized(.search_try_different) var tryDifferentText
    
    private var searchedForText: String {
        String(format: LocalizationManager.shared.localized(.search_searched_for), query)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 6) {
                Text(noResultsText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(tryDifferentText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 검색어 표시
            if !query.isEmpty {
                Text(searchedForText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}
