//
//  WritingPatternCalendar.swift
//  DiaryFriend
//

import SwiftUI

struct WritingPatternCalendar: View {
    let posts: [Post]
    let selectedMonth: Date
    
    // ⭐ 다국어 적용
    @Localized(.stats_entry_tracker) var headerText
    @Localized(.stats_no_entry) var noEntryText
    @Localized(.stats_entry) var entryText
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    // ⭐ DateFormatter로 요일 이름 자동 생성
    private var weekdays: [String] {
        let formatter = DateFormatter()
        let languageCode = LocalizationManager.shared.currentLanguage.code
        formatter.locale = Locale(identifier: languageCode)
        return formatter.veryShortWeekdaySymbols
    }
    
    private var postDatesSet: Set<String> {
        Set(posts.map { $0.entry_date })
    }
    
    private var monthData: MonthData {
        MonthData(date: selectedMonth)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header - Outside Card
            HStack {
                Text(headerText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .tracking(1.2)
                    .modernHighlight()
                
                Spacer()
            }
            
            // Card Content
            VStack(alignment: .leading, spacing: 16) {
                // Weekday Header
                HStack(spacing: 0) {
                    ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                        Text(day)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 8)
                
                // Calendar Grid (Heatmap)
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<42, id: \.self) { index in
                        if let day = dayNumber(for: index),
                           let date = monthData.date(for: day) {
                            DayCell(
                                day: day,
                                hasPost: postDatesSet.contains(DateUtility.shared.dateString(from: date)),
                                isToday: calendar.isDateInToday(date)
                            )
                        } else {
                            Color.clear
                                .frame(height: 32)
                        }
                    }
                }
                
                // Legend
                HStack(spacing: 20) {
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 12, height: 12)
                        Text(noEntryText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "00C896"))
                            .frame(width: 12, height: 12)
                        Text(entryText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.modernSurfacePrimary)
                    .shadow(color: .black.opacity(0.03), radius: 12, x: 0, y: 4)
            )
        }
    }
    
    private func dayNumber(for index: Int) -> Int? {
        let day = index - monthData.firstWeekday + 1
        return (day > 0 && day <= monthData.daysInMonth) ? day : nil
    }
}
