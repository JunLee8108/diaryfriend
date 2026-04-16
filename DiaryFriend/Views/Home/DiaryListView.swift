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
            MonthSelectorHeader(
                selectedMonth: $currentMonth,
                isLoading: .constant(false),
                onMonthChanged: { newMonth in
                    onMonthChanged(newMonth)
                }
            )
            .padding(.top, 4)
            .padding(.bottom, 8)

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
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
            }
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
