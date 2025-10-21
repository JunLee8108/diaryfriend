//
//  SearchResultItemView.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/9/25.
//

import SwiftUI

struct SearchResultItemView: View {
    @Environment(\.colorScheme) var colorScheme
    let item: PostDisplayItem
    let searchQuery: String
    
    var body: some View {
        NavigationLink(destination: PostDetailView(postId: item.postId)) {
            HStack(alignment: .top, spacing: 16) {
                // 날짜 컬럼
                VStack(spacing: 4) {
                    Text(item.dayNumber)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 2) {
                        Text(item.monthString)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text(item.weekday)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
                .frame(width: 50)
                
                // 내용 컬럼
                VStack(alignment: .leading, spacing: 8) {
                    // Mood 아이콘만 (형광펜 없음)
                    HStack(spacing: 6) {
                        Image(systemName: item.moodIcon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(item.moodColor)
                        
                        Spacer()
                    }
                    
                    // ⭐ 컨텐츠에만 형광펜 적용
                    HighlightedText(
                        text: item.contentPreview,
                        searchQuery: searchQuery,
                        font: .system(size: 15, weight: .regular),
                        lineLimit: 2
                    )
                    .foregroundColor(.primary.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.modernSurfacePrimary)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            VStack(spacing: 16) {
                SearchResultItemView(
                    item: PostDisplayItem(from: Post(
                        id: 1,
                        content: "Today was a happy day! I felt so happy.",
                        mood: "happy",
                        entry_date: "2025-01-15",
                        created_at: "2025-01-15T10:00:00Z",
                        user_id: UUID(),
                        ai_generated: false
                    )),
                    searchQuery: "happy"
                )
                
                SearchResultItemView(
                    item: PostDisplayItem(from: Post(
                        id: 2,
                        content: "Went to the beach today",
                        mood: "sunny",
                        entry_date: "2025-01-14",
                        created_at: "2025-01-14T10:00:00Z",
                        user_id: UUID(),
                        ai_generated: false
                    )),
                    searchQuery: "beach"
                )
            }
            .padding()
        }
    }
}
