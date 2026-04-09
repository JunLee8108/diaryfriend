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
        
        // ⭐ DateUtility가 이제 locale을 자동으로 적용!
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
    let currentMonth: Date
    
    // ⭐ 다국어 적용
    @Localized(.recent_posts_title) var recentTitle
    
    private var displayItems: [PostDisplayItem] {
        posts.map { PostDisplayItem(from: $0) }
    }
    
    // ⭐ locale 적용
    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.code)
        formatter.dateFormat = "MMM"
        return formatter.string(from: currentMonth).uppercased()
    }
    
    private var monthKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: currentMonth)
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            // RECENT 헤더
            HStack {
                Text(recentTitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .tracking(1.2)
                    .modernHighlight()
                
                Text(monthLabel)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                    .id(monthLabel)
                    .transition(.opacity)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .animation(.easeInOut(duration: 0.3), value: monthLabel)
            
            // ⭐ 콘텐츠 영역 - 애니메이션 분리
            contentView
                .id(monthKey)  // 월 변경 시 뷰 재생성
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: monthKey)
    }
    
    // ⭐ 별도 View로 분리 - Empty ↔ Posts 애니메이션
    @ViewBuilder
    private var contentView: some View {
        ZStack(alignment: .topLeading) {
            // Empty State
            EmptyRecentView(currentMonth: currentMonth)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(displayItems.isEmpty ? 1 : 0)
                .scaleEffect(displayItems.isEmpty ? 1 : 0.9)
            
            // Posts List
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(displayItems, id: \.id) { item in
                    RecentPostItemView(item: item)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .opacity(displayItems.isEmpty ? 0 : 1)
            .scaleEffect(displayItems.isEmpty ? 0.9 : 1)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: displayItems.isEmpty)
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
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 16,
                    topTrailingRadius: 16
                )
                .fill(Color.modernSurfacePrimary)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
            )
            .overlay(alignment: .leading) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 2,
                    bottomLeadingRadius: 2,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(Color(hex: "00C896"))
                .frame(width: 3)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 16,
                    topTrailingRadius: 16
                )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State
struct EmptyRecentView: View {
    let currentMonth: Date
    
    // ⭐ @Localized 추가!
    @Localized(.recent_no_posts) var noPostsTemplate
    
    private var noPostsMessage: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.code)
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: currentMonth)
        
        // ⭐ @Localized 프로퍼티 사용
        return String(format: noPostsTemplate, monthName)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 25, weight: .light))
                .foregroundColor(Color(hex:"00C896"))
            
            Text(noPostsMessage)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
