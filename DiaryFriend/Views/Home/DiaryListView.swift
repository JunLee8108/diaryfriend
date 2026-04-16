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
    let onMonthChanged: (Date) -> Void
    let onWriteDiary: (() -> Void)?

    @State private var tabSelection = 12
    private let calendar = Calendar.current
    private let centerIndex = 12

    @Localized(.home_list_empty_title) var emptyTitle
    @Localized(.home_list_empty_message) var emptyMessage

    private var isCurrentMonth: Bool {
        tabSelection == centerIndex
    }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더 (월 타이틀 + Today 버튼) — 캘린더와 동일한 컴포넌트 재사용
            CalendarHeader(
                currentMonth: currentMonth,
                isCurrentMonth: isCurrentMonth,
                onGoToToday: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        tabSelection = centerIndex
                    }
                }
            )
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 20)

            // TabView로 월 슬라이드 (캘린더와 동일한 UX)
            TabView(selection: $tabSelection) {
                ForEach(0..<24, id: \.self) { index in
                    MonthPostListPage(
                        month: monthForIndex(index),
                        emptyTitle: emptyTitle,
                        emptyMessage: emptyMessage,
                        onWriteDiary: onWriteDiary
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onChange(of: tabSelection) { _, newValue in
                let diff = newValue - centerIndex
                let newMonth = calendar.date(byAdding: .month, value: diff, to: Date()) ?? Date()
                currentMonth = newMonth
                onMonthChanged(newMonth)
            }
        }
    }

    private func monthForIndex(_ index: Int) -> Date {
        let diff = index - centerIndex
        return calendar.date(byAdding: .month, value: diff, to: Date()) ?? Date()
    }
}

// MARK: - 개별 월 포스트 리스트 페이지
private struct MonthPostListPage: View {
    @EnvironmentObject var dataStore: DataStore
    let month: Date
    let emptyTitle: String
    let emptyMessage: String
    let onWriteDiary: (() -> Void)?

    private var monthPosts: [Post] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: month)
        let monthNum = calendar.component(.month, from: month)
        return dataStore.posts(for: year, month: monthNum)
    }

    private var displayItems: [PostDisplayItem] {
        monthPosts.map { PostDisplayItem(from: $0) }
    }

    private var isFutureMonth: Bool {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        return monthStart > currentMonthStart
    }

    var body: some View {
        if displayItems.isEmpty {
            EmptyMonthListView(
                title: emptyTitle,
                message: emptyMessage,
                onWriteDiary: isFutureMonth ? nil : onWriteDiary
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(displayItems, id: \.id) { item in
                        RecentPostItemView(item: item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
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
