//
//  DateUtility.swift
//  DiaryFriend
//
//  앱 전체에서 사용하는 날짜 관련 유틸리티
//  entry_date는 date-only 필드이므로 시간대 변환 없이 처리
//

import Foundation
import SwiftUI

// MARK: - 날짜 포맷터 통합 클래스
class DateUtility {
    static let shared = DateUtility()
    
    private let calendar: Calendar
    private let dateFormatter: DateFormatter
    
    private init() {
        self.calendar = Calendar.current
        self.dateFormatter = DateFormatter()
        // 시간대 설정을 하지 않음 - date-only 필드이므로
        // DateFormatter는 기본적으로 시스템 시간대 사용
    }
    
    // MARK: - Core Date String 변환 (yyyy-MM-dd)
    
    /// Date를 "yyyy-MM-dd" 문자열로 변환
    func dateString(from date: Date) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    /// "yyyy-MM-dd" 문자열을 Date로 변환
    func date(from dateString: String) -> Date? {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: dateString)
    }
    
    // MARK: - Month String 변환 (yyyy-MM)
    
    /// Date를 "yyyy-MM" 문자열로 변환 (DataStore에서 사용)
    func monthKey(from date: Date) -> String {
        dateFormatter.dateFormat = "yyyy-MM"
        return dateFormatter.string(from: date)
    }
    
    /// "yyyy-MM" 문자열을 Date로 변환
    func date(fromMonthKey monthKey: String) -> Date? {
        dateFormatter.dateFormat = "yyyy-MM"
        return dateFormatter.date(from: monthKey)
    }
    
    // MARK: - Display Components (표시용 컴포넌트)
    
    /// 일(day) 숫자만 추출 (예: "05", "31")
    func dayNumber(from dateString: String) -> String {
        guard let date = self.date(from: dateString) else { return "" }
        let day = calendar.component(.day, from: date)
        return String(format: "%02d", day)
    }
    
    /// 월 짧은 이름 추출 (예: "Jan", "Feb", "Mar")
    func monthShortName(from dateString: String) -> String {
        guard let date = self.date(from: dateString) else { return "" }
        dateFormatter.dateFormat = "MMM"
        return dateFormatter.string(from: date)
    }
    
    /// 월 전체 이름 추출 (예: "January", "February")
    func monthFullName(from dateString: String) -> String {
        guard let date = self.date(from: dateString) else { return "" }
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: date)
    }
    
    /// 년도 추출 (예: "2025")
    func year(from dateString: String) -> String {
        guard let date = self.date(from: dateString) else { return "" }
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: date)
    }
    
    /// 요일 짧은 이름 (예: "Mon", "Tue")
    func weekdayShort(from dateString: String) -> String {
        guard let date = self.date(from: dateString) else { return "" }
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: date)
    }
    
    /// 요일 전체 이름 (예: "Monday", "Tuesday")
    func weekdayFull(from dateString: String) -> String {
        guard let date = self.date(from: dateString) else { return "" }
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: date)
    }
    
    // MARK: - Formatted Display Strings (조합된 표시 문자열)
    
    /// "MMM d, yyyy" 형식 (예: "Sep 17, 2025")
    func displayDate(from dateString: String) -> String {
        guard let date = self.date(from: dateString) else { return dateString }
        dateFormatter.dateFormat = "MMM d, yyyy"
        return dateFormatter.string(from: date)
    }
    
    /// "MMM yyyy" 형식 (예: "Sep 2025")
    func monthYear(from dateString: String) -> String {
        guard let date = self.date(from: dateString) else { return "" }
        dateFormatter.dateFormat = "MMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    /// "MMMM yyyy" 형식 (예: "September 2025")
    func monthYearFull(from dateString: String) -> String {
        guard let date = self.date(from: dateString) else { return "" }
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    // MARK: - Date from Date String (Date 객체 반환)
    
    /// "MMM yyyy" 형식에서 Date 반환 (캘린더 헤더용)
    func monthYear(from date: Date) -> String {
        dateFormatter.dateFormat = "MMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    // MARK: - Date Range Helpers (날짜 범위 헬퍼)
    
    /// 해당 월의 시작일
    func startOfMonth(for date: Date) -> Date? {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components)
    }
    
    /// 해당 월의 마지막일
    func endOfMonth(for date: Date) -> Date? {
        guard let startOfMonth = startOfMonth(for: date) else { return nil }
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
    }
    
    // MARK: - Comparison Helpers
    
    /// 두 날짜 문자열이 같은 날인지 확인
    func isSameDay(_ dateString1: String, _ dateString2: String) -> Bool {
        return dateString1 == dateString2
    }
    
    /// 날짜 문자열이 오늘인지 확인
    func isToday(_ dateString: String) -> Bool {
            let todayString = self.dateString(from: Date())
            return dateString == todayString
    }
    
    /// 날짜 문자열이 특정 월에 속하는지 확인
    func isInMonth(_ dateString: String, year: Int, month: Int) -> Bool {
        let monthPrefix = String(format: "%04d-%02d", year, month)
        return dateString.hasPrefix(monthPrefix)
    }
    
    // MARK: - Calendar Grid Helpers (캘린더 그리드용)
    
    /// 특정 월의 일수
    func daysInMonth(year: Int, month: Int) -> Int {
        let components = DateComponents(year: year, month: month)
        guard let date = calendar.date(from: components) else { return 30 }
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }
    
    /// 특정 월의 첫 날 요일 (0 = Sunday, 6 = Saturday)
    func firstWeekday(year: Int, month: Int) -> Int {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let date = calendar.date(from: components) else { return 0 }
        return calendar.component(.weekday, from: date) - 1
    }
    
    /// Date에서 년, 월, 일 컴포넌트 추출
    func dateComponents(from date: Date) -> (year: Int, month: Int, day: Int) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return (
            year: components.year ?? 0,
            month: components.month ?? 0,
            day: components.day ?? 0
        )
    }
    
    /// 년, 월, 일로 Date 생성
    func date(year: Int, month: Int, day: Int) -> Date? {
        let components = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: components)
    }
    
    // MARK: - Relative Date Helpers
    
    /// N개월 전/후 날짜
    func date(byAddingMonths months: Int, to date: Date) -> Date? {
        return calendar.date(byAdding: .month, value: months, to: date)
    }
    
    /// N일 전/후 날짜
    func date(byAddingDays days: Int, to date: Date) -> Date? {
        return calendar.date(byAdding: .day, value: days, to: date)
    }
    
    /// 현재 날짜 문자열 ("yyyy-MM-dd")
    func todayString() -> String {
        return dateString(from: Date())
    }
    
    /// 현재 월 문자열 ("yyyy-MM")
    func currentMonthKey() -> String {
        return monthKey(from: Date())
    }
}

// MARK: - MoodMapper (기존 코드 재활용)
class MoodMapper {
    static let shared = MoodMapper()
    
    private let moodData: [String: (icon: String, color: Color, label: String)] = [
        "happy": ("sun.max.fill", Color.yellow, "Happy"),
        "neutral": ("cloud", Color.gray, "Neutral"),
        "sad": ("cloud.rain.fill", Color(hex: "1CA3DE"), "Sad")
    ]
    
    private let defaultMood = ("cloud", Color.gray, "Neutral")
    
    private init() {}
    
    func icon(for mood: String?) -> String {
        guard let mood = mood?.lowercased() else {
            return defaultMood.0
        }
        return moodData[mood]?.icon ?? defaultMood.0
    }
    
    func color(for mood: String?) -> Color {
        guard let mood = mood?.lowercased() else {
            return defaultMood.1
        }
        return moodData[mood]?.color ?? defaultMood.1
    }
    
    func label(for mood: String?) -> String {
        guard let mood = mood?.lowercased() else {
            return defaultMood.2
        }
        return moodData[mood]?.label ?? defaultMood.2
    }
}

// MARK: - Debug Extension
#if DEBUG
extension DateUtility {
    /// 테스트용 날짜 문자열 생성
    func testDateStrings(daysFromToday: Int...) -> [String] {
        var results: [String] = []
        for days in daysFromToday {
            if let date = date(byAddingDays: days, to: Date()) {
                results.append(dateString(from: date))
            }
        }
        return results
    }
    
    /// 날짜 포맷 테스트 출력
    func printFormats(for dateString: String) {
        print("""
        📅 Date Formats for: \(dateString)
        - Day Number: \(dayNumber(from: dateString))
        - Month Short: \(monthShortName(from: dateString))
        - Month Full: \(monthFullName(from: dateString))
        - Year: \(year(from: dateString))
        - Weekday Short: \(weekdayShort(from: dateString))
        - Weekday Full: \(weekdayFull(from: dateString))
        - Display Date: \(displayDate(from: dateString))
        - Month Year: \(monthYear(from: dateString))
        - Is Today: \(isToday(dateString))
        """)
    }
}
#endif
