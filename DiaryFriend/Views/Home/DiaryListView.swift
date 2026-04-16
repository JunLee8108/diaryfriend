//
//  DiaryListView.swift
//  DiaryFriend
//
//  월별 일기 리스트 뷰 (캘린더 대체 모드)
//

import SwiftUI

struct DiaryListView: View {
    @EnvironmentObject var dataStore: DataStore
    @Binding var currentMonth: Date
    @Binding var showListView: Bool
    let onMonthChanged: (Date) -> Void
    let onWriteDiary: (() -> Void)?

    @Localized(.home_list_empty_title) var emptyTitle
    @Localized(.home_list_empty_message) var emptyMessage

    private var monthPosts: [Post] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentMonth)
        let monthNum = calendar.component(.month, from: currentMonth)
        return dataStore.posts(for: year, month: monthNum)
    }

    private var displayItems: [PostDisplayItem] {
        monthPosts.map { PostDisplayItem(from: $0) }
    }

    private var isFutureMonth: Bool {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) ?? currentMonth
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        return monthStart > currentMonthStart
    }

    var body: some View {
        VStack(spacing: 0) {
            // 월 선택 + 캘린더 토글 (한 줄)
            HStack {
                MonthSelectorHeader(
                    selectedMonth: $currentMonth,
                    isLoading: .constant(false),
                    onMonthChanged: { newMonth in
                        onMonthChanged(newMonth)
                    }
                )

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showListView = false
                    }
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // 포스트 리스트 또는 빈 상태
            if displayItems.isEmpty {
                EmptyMonthListView(
                    title: emptyTitle,
                    message: emptyMessage,
                    onWriteDiary: isFutureMonth ? nil : onWriteDiary
                )
            } else {
                ScrollView {
                    // 하나의 큰 카드 컨테이너
                    VStack(spacing: 0) {
                        ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, item in
                            NavigationLink(destination: PostDetailView(postId: item.postId)) {
                                CompactPostRow(item: item)
                            }
                            .buttonStyle(PlainButtonStyle())

                            if index < displayItems.count - 1 {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.modernSurfacePrimary)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

// MARK: - 컴팩트 포스트 행 (카드 내부용)
private struct CompactPostRow: View {
    let item: PostDisplayItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 날짜
            VStack(spacing: 2) {
                Text(item.dayNumber)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(item.weekday)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(width: 38)

            // 무드 + 내용
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: item.moodIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(item.moodColor)

                Text(item.contentPreview)
                    .font(.system(size: 14))
                    .foregroundColor(.primary.opacity(0.85))
                    .lineLimit(2)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - 빈 월 상태
private struct EmptyMonthListView: View {
    let title: String
    let message: String
    let onWriteDiary: (() -> Void)?

    @Localized(.home_list_write_diary) var writeDiaryText

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "book.closed")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary.opacity(0.4))

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text(message)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let onWriteDiary {
                Button(action: onWriteDiary) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text(writeDiaryText)
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "00C896"))
                    )
                }
                .padding(.top, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
