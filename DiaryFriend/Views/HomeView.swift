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
                    // 🎯 NEW: Intro Section
                    IntroGreetingSection()
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    
                    // 슬라이드 캘린더
                    SlideCalendarView(
                        currentMonth: $currentMonth,
                        selectedDate: $selectedDate,
                        postDatesSet: dataStore.postDates,
                        onMonthChanged: { newMonth in
                            Task {
                                await dataStore.ensureMonthLoaded(newMonth)
                            }
                        },
                        onDateTapped: { date in
                            handleDateTap(date)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    
                    // Recent Posts 섹션
                    RecentPostsSection(
                        posts: dataStore.recentPosts(for: currentMonth, limit: 3),
                        currentMonth: currentMonth  // 월 레이블 표시용
                    )
                    .padding(.bottom, 20)

                    // 배너 광고 (프리미엄/consent 미완 시 자동 숨김)
                    AdContainer(unitID: Config.AdMob.homeBannerUnitID)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                }
            }
            .refreshable {
                // 오프라인 체크
                guard networkMonitor.isConnected else {
                    showOfflineAlert = true
                    return
                }
                
                // ⭐ Diff 기반 새로고침
                await dataStore.refresh(centerDate: currentMonth)
                
                // ⭐ 에러 체크
                if let error = dataStore.errorMessage {
                    showSyncError = true
                    syncErrorMessage = error
                }
            }
            .smoothLoading(dataStore.isLoading)
            .sheet(item: $dayPostsData) { data in
                DayPostsSheet(
                    dateString: data.dateString
                )
                // EnvironmentObject는 자동 전파되지만 명시적으로 추가 (안전성)
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
                Color.clear.frame(height: 20)
            }
            .infoModal(
                isPresented: $showFutureDateInfo,
                title: futureDateTitle,
                message: futureDateMessage,
                icon: "calendar.badge.exclamationmark",
                iconColor: Color(hex: "FF6961")
            )
            .infoModal(
                isPresented: $showOfflineAlert,
                title: noInternetTitle,
                message: noInternetMessage,
                icon: "wifi.slash",
                iconColor: Color(hex: "FF6961")
            )
            .infoModal(
                isPresented: $showSyncError,
                title: "Sync Warning",
                message: syncErrorMessage,
                icon: "exclamationmark.triangle",
                iconColor: Color(hex: "FF6961")
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
            // ✅ NavigationCoordinator 사용
            PostCreationManager.shared.setSelectedDate(date)
            navigationCoordinator.push(.methodChoice(date))
        } else if posts.count == 1 {
            // ✅ NavigationCoordinator 사용
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
    let onMonthChanged: (Date) -> Void
    let onDateTapped: (Date) -> Void
    
    @State private var tabSelection = 50
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 20) {
            // 헤더
            CalendarHeader(
                currentMonth: currentMonth,
                onPreviousMonth: {
                    tabSelection -= 1
                },
                onNextMonth: {
                    tabSelection += 1
                }
            )
            
            // 요일 헤더
            WeekdayHeader()
            
            // TabView로 슬라이드 구현
            TabView(selection: $tabSelection) {
                ForEach(0..<100, id: \.self) { index in
                    CalendarGridView(
                        month: monthForIndex(index),
                        selectedDate: $selectedDate,
                        postDatesSet: postDatesSet,
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.modernSurfacePrimary)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
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
    
    // ⭐ 월 이름
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.code)
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentMonth)
    }
    
    // ⭐ 연도
    private var yearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.code)
        formatter.dateFormat = "yyyy"
        return formatter.string(from: currentMonth)
    }
    
    // ⭐ 한국어에서 "년" 추가
    private var yearWithSuffix: String {
        if LocalizationManager.shared.currentLanguage == .korean {
            return "\(yearString)년"
        } else {
            return yearString
        }
    }
    
    // ⭐ 한국어에서 "월" 추가
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
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
            }
            
            Spacer()
            
            // ⭐ 언어별 순서 분기
            if LocalizationManager.shared.currentLanguage == .korean {
                // 한국어: 2025년 1월
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(yearWithSuffix)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.85))
                    
                    Text(monthWithSuffix)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    
                }
            } else {
                // 영어: January 2025
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(monthName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(yearString)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.primary.opacity(0.65))
                }
            }
            
            Spacer()
            
            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
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
    
    private let sundayColor = Color(hex:"00A077")
    private let saturdayColor = Color(hex:"FF7AB2")
    
    private func colorForWeekday(at index: Int) -> Color {
        switch index {
        case 0: return sundayColor
        case 6: return saturdayColor
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
    let onDateTapped: (Date) -> Void
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    private let sundayColor = Color(hex:"00A077")
    private let saturdayColor = Color(hex:"FF7AB2")
    
    private var monthData: MonthData {
        MonthData(date: month)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<42, id: \.self) { index in
                if let day = dayNumber(for: index),
                   let date = monthData.date(for: day) {
                    OptimizedDayView(
                        date: date,
                        day: day,
                        selectedDate: selectedDate,
                        hasPost: postDatesSet.contains(DateUtility.shared.dateString(from: date)),
                        weekdayColor: getWeekdayColor(for: index),
                        onTap: {
                            onDateTapped(date)
                        }
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
        case 0: return sundayColor
        case 6: return saturdayColor
        default: return nil
        }
    }
}

// MARK: - 형광펜 밑줄 Shape
struct HighlighterUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let startY = rect.maxY - 6
        let endY = rect.maxY - 5
        
        path.move(to: CGPoint(x: rect.minX + 2, y: startY))
        
        path.addCurve(
            to: CGPoint(x: rect.maxX - 2, y: endY),
            control1: CGPoint(x: rect.midX - 3, y: startY + 0.5),
            control2: CGPoint(x: rect.midX + 3, y: endY - 0.5)
        )
        
        path.addLine(to: CGPoint(x: rect.maxX - 2, y: endY + 5))
        path.addCurve(
            to: CGPoint(x: rect.minX + 2, y: startY + 7),
            control1: CGPoint(x: rect.midX + 3, y: endY + 7.5),
            control2: CGPoint(x: rect.midX - 3, y: startY + 6.5)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - 최적화된 Day View
struct OptimizedDayView: View {
    let date: Date
    let day: Int
    let selectedDate: Date
    let hasPost: Bool
    let weekdayColor: Color?
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private var highlighterColor: Color {
        Color(hex:"00C896").opacity(0.3)
    }
    
    private var textColor: Color {
        if hasPost {
            return Color(hex: "00C896")
        } else if let weekdayColor = weekdayColor {
            return weekdayColor.opacity(0.9)
        } else {
            return .primary
        }
    }
    
    var body: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex:"89dfbc").opacity(0.1))
            }
            
            if isToday {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex:"89dfbc"), lineWidth: 2)
                    .padding(0.5)
            }
            
            ZStack {
                if hasPost {
                    HighlighterUnderline()
                        .fill(highlighterColor)
                        .frame(width: 22, height: 20)
                        .offset(y: 3)
                }
                
                Text("\(day)")
                    .font(.system(size: 16, weight: hasPost ? .semibold : .regular))
                    .foregroundColor(textColor)
            }
        }
        .frame(width: 40, height: 40)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Month Data Helper
struct MonthData {
    let date: Date
    private let calendar = Calendar.current
    
    var year: Int {
        calendar.component(.year, from: date)
    }
    
    var month: Int {
        calendar.component(.month, from: date)
    }
    
    var daysInMonth: Int {
        DateUtility.shared.daysInMonth(year: year, month: month)
    }
    
    var firstWeekday: Int {
        DateUtility.shared.firstWeekday(year: year, month: month)
    }
    
    func date(for day: Int) -> Date? {
        DateUtility.shared.date(year: year, month: month, day: day)
    }
}
