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
    let onWriteDiary: (() -> Void)?

    init(posts: [Post], currentMonth: Date, onWriteDiary: (() -> Void)? = nil) {
        self.posts = posts
        self.currentMonth = currentMonth
        self.onWriteDiary = onWriteDiary
    }

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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                .animation(.easeInOut(duration: 0.3), value: monthLabel)
        }
    }

    // ⭐ 별도 View로 분리 - Empty ↔ Posts 애니메이션
    @ViewBuilder
    private var contentView: some View {
        Group {
            if displayItems.isEmpty {
                // Empty State
                EmptyRecentView(currentMonth: currentMonth, onWriteDiary: onWriteDiary)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Posts List
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(displayItems, id: \.id) { item in
                        RecentPostItemView(item: item)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .id(monthLabel)
        .transition(.opacity)
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.modernSurfacePrimary)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
            )
            .overlay(alignment: .topTrailing) {
                DogEarShape()
                    .fill(item.moodColor.opacity(0.25))
                    .frame(width: 18, height: 18)
                    .shadow(color: item.moodColor.opacity(0.1), radius: 2, x: -1, y: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Dog-ear Shape (접힌 페이지 모서리)
struct DogEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Empty State
struct EmptyRecentView: View {
    let currentMonth: Date
    let onWriteDiary: (() -> Void)?

    @Localized(.recent_no_posts) var noPostsTemplate
    private var writeDiaryText: String {
        NSLocalizedString("recent_posts.write_diary", comment: "")
    }

    private var noPostsMessage: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.code)
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: currentMonth)

        return String(format: noPostsTemplate, monthName)
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar")
                .font(.system(size: 25, weight: .light))
                .foregroundColor(Color(hex: "00C896"))

            Text(noPostsMessage)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)

            if let onWriteDiary = onWriteDiary {
                Button(action: onWriteDiary) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 12, weight: .semibold))
                        Text(writeDiaryText)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color(hex: "00C896"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color(hex: "00C896").opacity(0.12))
                    )
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.modernSurfacePrimary)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        )
    }
}
