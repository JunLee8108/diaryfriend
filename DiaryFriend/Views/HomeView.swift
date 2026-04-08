//
//  HomeView.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/16/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataStore: DataStore
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineAlert = false
    @State private var selectedDate = Date()
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @State private var currentMonth = Date()

    // Info modal state
    @State private var showFutureDateInfo = false

    // 동기화 에러 상태
    @State private var showSyncError = false
    @State private var syncErrorMessage = ""

    // 다국어 적용
    @Localized(.home_future_date_title) var futureDateTitle
    @Localized(.home_future_date_message) var futureDateMessage
    @Localized(.home_no_internet_title) var noInternetTitle
    @Localized(.home_no_internet_message) var noInternetMessage

    // item 기반 sheet를 위한 구조체
    struct DayPostsData: Identifiable {
        let id = UUID()
        let dateString: String
    }

    // sheet에 전달할 데이터
    @State private var dayPostsData: DayPostsData?

    var body: some View {
        NavigationStack(path: $navigationCoordinator.path) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 🎯 Intro Hero Card
                    IntroGreetingSection()
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .padding(.bottom, 14)

                    // 슬라이드 캘린더
                    SlideCalendarView(
                        currentMonth: $currentMonth,
                        selectedDate: $selectedDate,
                        postDatesSet: dataStore.postDates,
                        posts: dataStore.posts,
                        onMonthChanged: { newMonth in
                            Task {
                                await dataStore.ensureMonthLoaded(newMonth)
                            }
                        },
                        onDateTapped: { date in
                            handleDateTap(date)
                        }
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 24)

                    // Recent Posts 섹션
                    RecentPostsSection(
                        posts: dataStore.recentPosts(for: currentMonth, limit: 3),
                        currentMonth: currentMonth
                    )
                    .padding(.bottom, 14)
                }
            }
            .refreshable {
                guard networkMonitor.isConnected else {
                    showOfflineAlert = true
                    return
                }
                await dataStore.refresh(centerDate: currentMonth)
                if let error = dataStore.errorMessage {
                    showSyncError = true
                    syncErrorMessage = error
                }
            }
            .smoothLoading(dataStore.isLoading)
            .sheet(item: $dayPostsData) { data in
                DayPostsSheet(dateString: data.dateString)
                    .environmentObject(dataStore)
            }
            .navigationDestination(for: PostDestination.self) { destination in
                switch destination {
                case .methodChoice(let date):
                    PostMethodChoiceView(selectedDate: date)
                        .environmentObject(navigationCoordinator)
                case .aiSelect:
                    PostAISelectView()
                        .environmentObject(navigationCoordinator)
                case .aiConversation(let characterId):
                    PostAIConversationView(
                        characterId: characterId,
                        selectedDate: PostCreationManager.shared.selectedDate ?? Date()
                    )
                    .environmentObject(navigationCoordinator)
                case .aiReview(let data):
                    PostAIReviewView(
                        characterId: data.characterId,
                        selectedDate: data.selectedDate,
                        sessionId: data.sessionId,
                        generatedContent: data.content,
                        aiMood: data.mood,
                        aiHashtags: data.hashtags
                    )
                    .environmentObject(navigationCoordinator)
                case .manualWrite:
                    PostManualWriteView()
                        .environmentObject(navigationCoordinator)
                case .detail(let postId):
                    PostDetailView(postId: postId)
                        .environmentObject(navigationCoordinator)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 14)
            }
            .infoModal(
                isPresented: $showFutureDateInfo,
                title: futureDateTitle,
                message: futureDateMessage,
                icon: "calendar.badge.exclamationmark",
                iconColor: Color.brand
            )
            .infoModal(
                isPresented: $showOfflineAlert,
                title: noInternetTitle,
                message: noInternetMessage,
                icon: "wifi.slash",
                iconColor: Color.brand
            )
            .infoModal(
                isPresented: $showSyncError,
                title: "Sync Warning",
                message: syncErrorMessage,
                icon: "exclamationmark.triangle",
                iconColor: Color.brand
            )
            .background(Color.modernBackground)
        }
    }

    private func handleDateTap(_ date: Date) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfSelectedDate = calendar.startOfDay(for: date)

        if startOfSelectedDate > startOfToday {
            showFutureDateInfo = true
            return
        }

        selectedDate = date
        let dateString = DateUtility.shared.dateString(from: date)
        let posts = dataStore.posts(for: dateString)

        if posts.isEmpty {
            PostCreationManager.shared.setSelectedDate(date)
            navigationCoordinator.push(.methodChoice(date))
        } else if posts.count == 1 {
            navigationCoordinator.push(.detail(posts.first!.id))
        } else {
            dayPostsData = DayPostsData(dateString: dateString)
        }
    }
}

// MARK: - 슬라이드 캘린더
struct SlideCalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let postDatesSet: Set<String>
    let posts: [Post]
    let onMonthChanged: (Date) -> Void
    let onDateTapped: (Date) -> Void

    @State private var tabSelection = 50
    private let calendar = Calendar.current

    /// 날짜별 무드 맵핑
    private var moodForDate: [String: String] {
        var map: [String: String] = [:]
        for post in posts {
            if map[post.entry_date] == nil {
                map[post.entry_date] = post.mood
            }
        }
        return map
    }

    var body: some View {
        VStack(spacing: 16) {
            CalendarHeader(
                currentMonth: currentMonth,
                onPreviousMonth: { tabSelection -= 1 },
                onNextMonth: { tabSelection += 1 }
            )

            WeekdayHeader()

            TabView(selection: $tabSelection) {
                ForEach(0..<100, id: \.self) { index in
                    CalendarGridView(
                        month: monthForIndex(index),
                        selectedDate: $selectedDate,
                        postDatesSet: postDatesSet,
                        moodForDate: moodForDate,
                        onDateTapped: onDateTapped
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 300)
            .onChange(of: tabSelection) { oldValue, newValue in
                let diff = newValue - 50
                let newMonth = calendar.date(byAdding: .month, value: diff, to: Date()) ?? Date()
                currentMonth = newMonth
                onMonthChanged(newMonth)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.modernSurfacePrimary)
                .shadow(color: Color.brand.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }

    private func monthForIndex(_ index: Int) -> Date {
        let diff = index - 50
        return calendar.date(byAdding: .month, value: diff, to: Date()) ?? Date()
    }
}

// MARK: - 캘린더 헤더 컴포넌트
struct CalendarHeader: View {
    let currentMonth: Date
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.code)
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentMonth)
    }

    private var yearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.code)
        formatter.dateFormat = "yyyy"
        return formatter.string(from: currentMonth)
    }

    private var yearWithSuffix: String {
        if LocalizationManager.shared.currentLanguage == .korean {
            return "\(yearString)년"
        } else {
            return yearString
        }
    }

    private var monthWithSuffix: String {
        if LocalizationManager.shared.currentLanguage == .korean {
            let monthNumber = Calendar.current.component(.month, from: currentMonth)
            return "\(monthNumber)월"
        } else {
            return monthName
        }
    }

    var body: some View {
        HStack {
            Button(action: onPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.brand)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            if LocalizationManager.shared.currentLanguage == .korean {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(yearWithSuffix)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.85))
                    Text(monthWithSuffix)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(monthName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(yearString)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primary.opacity(0.65))
                }
            }

            Spacer()

            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brand)
                    .frame(width: 36, height: 36)
            }
        }
    }
}

// MARK: - 요일 헤더
struct WeekdayHeader: View {
    private var weekdays: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.code)
        return formatter.shortWeekdaySymbols
    }

    private func colorForWeekday(at index: Int) -> Color {
        switch index {
        case 0: return .sundayColor
        case 6: return .saturdayColor
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                Text(day)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(colorForWeekday(at: index))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - 캘린더 그리드
struct CalendarGridView: View {
    let month: Date
    @Binding var selectedDate: Date
    let postDatesSet: Set<String>
    let moodForDate: [String: String]
    let onDateTapped: (Date) -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var monthData: MonthData {
        MonthData(date: month)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<42, id: \.self) { index in
                if let day = dayNumber(for: index),
                   let date = monthData.date(for: day) {
                    let dateString = DateUtility.shared.dateString(from: date)
                    OptimizedDayView(
                        date: date,
                        day: day,
                        selectedDate: selectedDate,
                        hasPost: postDatesSet.contains(dateString),
                        mood: moodForDate[dateString],
                        weekdayColor: getWeekdayColor(for: index),
                        onTap: { onDateTapped(date) }
                    )
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
    }

    private func dayNumber(for index: Int) -> Int? {
        let day = index - monthData.firstWeekday + 1
        return (day > 0 && day <= monthData.daysInMonth) ? day : nil
    }

    private func getWeekdayColor(for index: Int) -> Color? {
        let weekday = index % 7
        switch weekday {
        case 0: return .sundayColor
        case 6: return .saturdayColor
        default: return nil
        }
    }
}

// MARK: - 최적화된 Day View (무드 이모지 지원)
struct OptimizedDayView: View {
    let date: Date
    let day: Int
    let selectedDate: Date
    let hasPost: Bool
    let mood: String?
    let weekdayColor: Color?
    let onTap: () -> Void

    private let calendar = Calendar.current

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private var moodEmoji: String? {
        guard hasPost, let mood = mood?.lowercased() else { return nil }
        switch mood {
        case "happy":   return "😊"
        case "sad":     return "😢"
        case "neutral": return "😐"
        default:        return "📝"
        }
    }

    private var textColor: Color {
        if hasPost {
            return .brand
        } else if let weekdayColor = weekdayColor {
            return weekdayColor.opacity(0.9)
        } else {
            return .primary
        }
    }

    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.brandBlush.opacity(0.5))
                }

                if isToday {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.brandLight.opacity(0.3))
                }

                Text("\(day)")
                    .font(.system(size: 15, weight: hasPost ? .semibold : .regular))
                    .foregroundColor(textColor)
            }
            .frame(width: 36, height: 30)

            // 무드 이모지 표시
            if let emoji = moodEmoji {
                Text(emoji)
                    .font(.system(size: 10))
            } else {
                Color.clear
                    .frame(height: 12)
            }
        }
        .frame(width: 40, height: 44)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Month Data Helper
struct MonthData {
    let date: Date
    private let calendar = Calendar.current

    var year: Int { calendar.component(.year, from: date) }
    var month: Int { calendar.component(.month, from: date) }
    var daysInMonth: Int { DateUtility.shared.daysInMonth(year: year, month: month) }
    var firstWeekday: Int { DateUtility.shared.firstWeekday(year: year, month: month) }

    func date(for day: Int) -> Date? {
        DateUtility.shared.date(year: year, month: month, day: day)
    }
}
