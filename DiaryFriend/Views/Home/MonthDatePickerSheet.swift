//
//  MonthDatePickerSheet.swift
//  DiaryFriend
//

import SwiftUI

struct MonthDatePickerSheet: View {
    let currentMonth: Date
    let onConfirm: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @State private var selectedDate: Date

    @Localized(.recent_select_date_title) var titleText
    @Localized(.recent_select_date_confirm) var confirmText
    @Localized(.common_cancel) var cancelText

    init(currentMonth: Date, onConfirm: @escaping (Date) -> Void) {
        self.currentMonth = currentMonth
        self.onConfirm = onConfirm

        // 선택 가능한 기본 날짜: 해당 월의 오늘 또는 해당 월의 1일
        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)

        let monthComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let todayComponents = calendar.dateComponents([.year, .month], from: today)

        if monthComponents.year == todayComponents.year &&
            monthComponents.month == todayComponents.month {
            _selectedDate = State(initialValue: startOfToday)
        } else {
            let firstOfMonth = calendar.date(from: monthComponents) ?? currentMonth
            _selectedDate = State(initialValue: firstOfMonth)
        }
    }

    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let monthComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstOfMonth = calendar.date(from: monthComponents),
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth),
              let lastOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth) else {
            return today...today
        }

        let upperBound = min(lastOfMonth, today)
        return firstOfMonth...upperBound
    }

    private var localeIdentifier: String {
        localizationManager.currentLanguage.code
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: dateRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: localeIdentifier))
                .tint(Color(hex: "00C896"))
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 12)
            .background(Color.modernBackground)
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(cancelText) {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onConfirm(selectedDate)
                        dismiss()
                    }) {
                        Text(confirmText)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "00C896"))
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}
