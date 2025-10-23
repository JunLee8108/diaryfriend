//
//  SearchResultsSection.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/9/25.
//

import SwiftUI

struct SearchResultsSection: View {
    let posts: [Post]
    let searchQuery: String
    
    // PostDisplayItem으로 변환
    private var displayItems: [PostDisplayItem] {
        posts.map { PostDisplayItem(from: $0) }
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            // 결과 헤더
            HStack {
                Text("RESULTS")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .tracking(1.2)
                    .modernHighlight()
                
                Text("(\(posts.count))")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // 검색 결과 리스트
            ForEach(displayItems, id: \.id) { item in
                SearchResultItemView(item: item, searchQuery: searchQuery)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
    }
}
