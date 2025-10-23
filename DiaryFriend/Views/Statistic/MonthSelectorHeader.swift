//
//  MonthSelectorHeader.swift
//  DiaryFriend
//

import SwiftUI

struct MonthSelectorHeader: View {
    @Binding var selectedMonth: Date
    @Binding var isLoading: Bool
    let onMonthChanged: (Date) async -> Void
    
    @State private var showMonthPicker = false
    
    // ⭐ 언어별 날짜 형식 적용
    private var monthYearString: String {
        let formatter = DateFormatter()
        
        // 현재 언어 코드
        let languageCode = LocalizationManager.shared.currentLanguage.code
        formatter.locale = Locale(identifier: languageCode)
        
        // 언어별 형식 분기
        if LocalizationManager.shared.currentLanguage == .korean {
            formatter.dateFormat = "yyyy년 M월"  // 2025년 1월
        } else {
            formatter.dateFormat = "MMMM yyyy"   // January 2025
        }
        
        return formatter.string(from: selectedMonth)
    }
    
    var body: some View {
        Button(action: {
            showMonthPicker = true
        }) {
            HStack {
                Spacer()
                
                HStack(spacing: 8) {
                    Text(monthYearString)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Image(systemName: showMonthPicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "00C896"))
                        .animation(.easeInOut(duration: 0.2), value: showMonthPicker)
                }
                
                Spacer()
            }
            .frame(height: 56)
        }
        .disabled(isLoading)
        .sheet(isPresented: $showMonthPicker) {
            
        } content: {
            CustomMonthPickerSheet(
                selectedMonth: $selectedMonth,
                onMonthSelected: { newDate in
                    Task {
                        await onMonthChanged(newDate)
                    }
                }
            )
            .presentationDetents([.height(480)])
            .presentationDragIndicator(.visible)
        }
    }
}
