//
//  CustomMonthPickerSheet.swift
//  DiaryFriend
//

import SwiftUI

struct CustomMonthPickerSheet: View {
    @Binding var selectedMonth: Date
    
    let onMonthSelected: (Date) -> Void
    
    @State private var selectedYear: Int
    @State private var selectedMonthIndex: Int
    
    @Environment(\.dismiss) private var dismiss
    
    private let calendar = Calendar.current
    private let months = [
        "Jan", "Feb", "Mar", "Apr",
        "May", "Jun", "Jul", "Aug",
        "Sep", "Oct", "Nov", "Dec"
    ]
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    init(
        selectedMonth: Binding<Date>,
        onMonthSelected: @escaping (Date) -> Void
    ) {
        self._selectedMonth = selectedMonth
        self.onMonthSelected = onMonthSelected
        
        let year = Calendar.current.component(.year, from: selectedMonth.wrappedValue)
        let month = Calendar.current.component(.month, from: selectedMonth.wrappedValue)
        self._selectedYear = State(initialValue: year)
        self._selectedMonthIndex = State(initialValue: month - 1)
    }
    
    // ⭐ 오늘 날짜의 월인지 판단
    private func isCurrentMonth(year: Int, monthIndex: Int) -> Bool {
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        return year == currentYear && (monthIndex + 1) == currentMonth
    }
    
    // ⭐ 선택된 월인지 판단 (year + month 모두 비교)
    private func isSelectedMonth(year: Int, monthIndex: Int) -> Bool {
        let selectedYear = calendar.component(.year, from: selectedMonth)
        let selectedMonthNum = calendar.component(.month, from: selectedMonth)
        return year == selectedYear && (monthIndex + 1) == selectedMonthNum
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                // Year Selector
                YearSelector(selectedYear: $selectedYear)
                    .padding(.top, 24)
                
                // Month Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<12, id: \.self) { index in
                        MonthCell(
                            monthName: months[index],
                            isSelected: isSelectedMonth(year: selectedYear, monthIndex: index),  // ⭐ 수정
                            isCurrent: isCurrentMonth(year: selectedYear, monthIndex: index),    // ⭐ 추가
                            onTap: {
                                selectedMonthIndex = index
                                
                                // 새로운 Date 생성
                                var components = DateComponents()
                                components.year = selectedYear
                                components.month = index + 1
                                components.day = 1
                                
                                if let newDate = calendar.date(from: components) {
                                    print("✅ 월 선택: \(DateUtility.shared.monthKey(from: newDate))")
                                    selectedMonth = newDate
                                    
                                    // 콜백 호출
                                    onMonthSelected(newDate)
                                    
                                    // Sheet 닫기
                                    dismiss()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .background(Color.modernBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        print("❌ Month Picker - Cancel 클릭")
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}
