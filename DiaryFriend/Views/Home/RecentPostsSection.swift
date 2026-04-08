//
//  RecentPostsSection.swift
//  DiaryFriend
//
//  Recent Posts UI Components — Soft & Cozy Mood Card Design
//

import SwiftUI
import Foundation

// MARK: - 미리 계산된 포스트 표시 데이터
struct PostDisplayItem {
    let id: Int
    let postId: Int

    // 날짜 정보
    let dayNumber: String
    let monthString: String
    let weekday: String
    let fullDate: String

    // 무드 정보
    let moodIcon: String
    let moodColor: Color
    let moodLabel: String
    let moodAccent: Color

    // 콘텐츠
    let contentPreview: String

    init(from post: Post) {
        self.id = post.id
        self.postId = post.id

        self.dayNumber = DateUtility.shared.dayNumber(from: post.entry_date)
        self.monthString = DateUtility.shared.monthShortName(from: post.entry_date).uppercased()
        self.weekday = DateUtility.shared.weekdayShort(from: post.entry_date)

        // 날짜 포맷: "Apr 7, Mon"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.code)
        formatter.dateFormat = "MMM d, E"
        if let date = DateUtility.shared.date(from: post.entry_date) {
            self.fullDate = formatter.string(from: date)
        } else {
            self.fullDate = post.entry_date
        }

        self.moodIcon = MoodMapper.shared.icon(for: post.mood)
        self.moodColor = MoodMapper.shared.color(for: post.mood)
        self.moodLabel = MoodMapper.shared.label(for: post.mood)

        // 무드별 액센트 컬러
        switch post.mood?.lowercased() {
        case "happy":   self.moodAccent = Color(hex: "FFD700")   // 골드
        case "sad":     self.moodAccent = Color(hex: "7EB6D8")   // 소프트 블루
        default:        self.moodAccent = Color.brandLavender     // 라벤더
        }

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

    @Localized(.recent_posts_title) var recentTitle

    private var displayItems: [PostDisplayItem] {
        posts.map { PostDisplayItem(from: $0) }
    }

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
            // 헤더
            HStack {
                Text(recentTitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .tracking(1.2)
                    .modernHighlight(color: .brand, opacity: 0.15)

                Text(monthLabel)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                    .id(monthLabel)
                    .transition(.opacity)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
            .animation(.easeInOut(duration: 0.3), value: monthLabel)

            // 콘텐츠 영역
            contentView
                .id(monthKey)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: monthKey)
    }

    @ViewBuilder
    private var contentView: some View {
        ZStack(alignment: .topLeading) {
            EmptyRecentView(currentMonth: currentMonth)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(displayItems.isEmpty ? 1 : 0)
                .scaleEffect(displayItems.isEmpty ? 1 : 0.9)

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(displayItems, id: \.id) { item in
                    RecentPostItemView(item: item)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .opacity(displayItems.isEmpty ? 0 : 1)
            .scaleEffect(displayItems.isEmpty ? 0.9 : 1)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: displayItems.isEmpty)
    }
}

// MARK: - Recent Post Item View (무드 액센트 카드)
struct RecentPostItemView: View {
    @Environment(\.colorScheme) var colorScheme
    let item: PostDisplayItem

    var body: some View {
        NavigationLink(destination: PostDetailView(postId: item.postId)) {
            HStack(spacing: 0) {
                // 좌측 무드 액센트 바
                RoundedRectangle(cornerRadius: 2)
                    .fill(item.moodAccent)
                    .frame(width: 4)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    // 상단: 무드 + 날짜
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: item.moodIcon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(item.moodColor)
                            Text(item.moodLabel)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(item.moodColor)
                        }

                        Spacer()

                        Text(item.fullDate)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.8))
                    }

                    // 내용 미리보기
                    Text(item.contentPreview)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.primary.opacity(0.85))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 12)
                .padding(.trailing, 14)
                .padding(.vertical, 14)
            }
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.modernSurfacePrimary)
                    .shadow(color: Color.brand.opacity(0.06), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State
struct EmptyRecentView: View {
    let currentMonth: Date

    private var noPostsMessage: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.code)
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: currentMonth)
        return String(
            format: LocalizationManager.shared.localized(.recent_no_posts),
            monthName
        )
    }

    private var ctaText: String {
        LocalizationManager.shared.currentLanguage == .korean
            ? "✏️ 일기 쓰러 가기" : "✏️ Start Writing"
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("📔✨")
                .font(.system(size: 32))

            Text(noPostsMessage)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)

            Text(ctaText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.brand)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
