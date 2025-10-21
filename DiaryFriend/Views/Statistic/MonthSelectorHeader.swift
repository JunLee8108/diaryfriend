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
    
    // ⭐ tempSelectedMonth 제거 (더 이상 필요 없음)
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    var body: some View {
        Button(action: {
            showMonthPicker = true
            print("📅 Month Picker 열기")
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
//            .background(
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(Color.modernSurfacePrimary)
//                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 16)
//                    .strokeBorder(
//                        isLoading ? Color(hex: "00C896").opacity(0.3) : Color.clear,
//                        lineWidth: 2
//                    )
//                    .animation(.easeInOut(duration: 0.3), value: isLoading)
//            )
        }
        .disabled(isLoading)
        .sheet(isPresented: $showMonthPicker) {
            // ⭐ onDismiss에서 sheet가 닫힐 때 처리
            print("📅 Month Picker 닫힘")
        } content: {
            CustomMonthPickerSheet(
                selectedMonth: $selectedMonth,
                onMonthSelected: { newDate in
                    print("✅ Month Picker - 월 선택됨")
                    print("   선택된 월: \(DateUtility.shared.monthKey(from: newDate))")
                    
                    // ⭐ async 함수 호출
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

#Preview {
    VStack(spacing: 20) {
        // Normal state
        MonthSelectorHeader(
            selectedMonth: .constant(Date()),
            isLoading: .constant(false),
            onMonthChanged: { newMonth in
                print("Month changed to: \(newMonth)")
            }
        )
        
        // Loading state
        MonthSelectorHeader(
            selectedMonth: .constant(Date()),
            isLoading: .constant(true),
            onMonthChanged: { newMonth in
                print("Month changed to: \(newMonth)")
            }
        )
    }
    .padding()
    .background(Color.modernBackground)
}
