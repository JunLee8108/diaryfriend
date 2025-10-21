//
//  RecentPostsSection.swift
//  DiaryFriend
//
//  Recent Posts UI Components - 순환 참조 해결 버전
//

import SwiftUI
import Foundation

// MARK: - 미리 계산된 포스트 표시 데이터
struct PostDisplayItem {
    let id: Int
    let postId: Int
    
    // 미리 계산된 날짜 정보
    let dayNumber: String
    let monthString: String
    let weekday: String
    
    // 미리 계산된 무드 정보
    let moodIcon: String
    let moodColor: Color
    
    // 미리 처리된 콘텐츠
    let contentPreview: String
    
    init(from post: Post) {
        self.id = post.id
        self.postId = post.id
        
        // 날짜 정보 한 번만 계산
        self.dayNumber = DateUtility.shared.dayNumber(from: post.entry_date)
        self.monthString = DateUtility.shared.monthShortName(from: post.entry_date).uppercased()
        self.weekday = DateUtility.shared.weekdayShort(from: post.entry_date)
        
        // 무드 정보 한 번만 계산
        self.moodIcon = MoodMapper.shared.icon(for: post.mood)
        self.moodColor = MoodMapper.shared.color(for: post.mood)
        
        // 콘텐츠 미리보기 한 번만 처리
        if #available(iOS 15.0, *) {
            let plainContent = post.content.htmlToPlainText()
            self.contentPreview = String(plainContent.prefix(100))
        } else {
            let plainContent = post.content.removingHTMLTags()
            self.contentPreview = String(plainContent.prefix(100))
        }
    }
}

// MARK: - Recent Posts Section
struct RecentPostsSection: View {
    let posts: [Post]
    
    // 포스트를 미리 변환
    private var displayItems: [PostDisplayItem] {
        posts.map { PostDisplayItem(from: $0) }
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            // RECENT 헤더
            HStack {
                Text("RECENT")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .tracking(1.2)
                    .modernHighlight()  // ← 여기에 추가!
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // 포스트 리스트
            if displayItems.isEmpty {
                EmptyRecentView()
            } else {
                ForEach(displayItems, id: \.id) { item in
                    RecentPostItemView(item: item)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
            }
        }
    }
}

// MARK: - Recent Post Item View (순수 표시용)
struct RecentPostItemView: View {
    @Environment(\.colorScheme) var colorScheme
    let item: PostDisplayItem
    
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
                    // Mood 아이콘
                    HStack(spacing: 6) {
                        Image(systemName: item.moodIcon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(item.moodColor)
                        
                        Spacer()
                    }
                    
                    // 내용 미리보기
                    Text(item.contentPreview)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.primary.opacity(0.9))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
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

// MARK: - Empty State
struct EmptyRecentView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex:"00C896").opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex:"00C896"))
            }
            
            VStack(spacing: 6) {
                Text("Your story begins here")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Write your first memory today")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}
