//
//  YearSelector.swift
//  DiaryFriend
//

import SwiftUI

struct YearSelector: View {
    @Binding var selectedYear: Int
    
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let minYear = 2020
    
    @State private var showYearPicker = false
    
    private var yearString: String {
        String(format: "%d", selectedYear)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Previous Year Button
            Button(action: {
                if selectedYear > minYear {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedYear -= 1
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(selectedYear > minYear ? Color(hex: "00C896") : .secondary.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            .disabled(selectedYear <= minYear)
            
            // Year Display
            Button(action: {
                showYearPicker = true
            }) {
                Text(verbatim: yearString)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(minWidth: 100)
                    .monospacedDigit()
            }
            .popover(isPresented: $showYearPicker, arrowEdge: .bottom) {
                YearWheelPicker(
                    selectedYear: $selectedYear,
                    minYear: minYear,
                    maxYear: currentYear
                )
                .presentationCompactAdaptation(.popover)
            }
            
            // Next Year Button
            Button(action: {
                if selectedYear < currentYear {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedYear += 1
                    }
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(selectedYear < currentYear ? Color(hex: "00C896") : .secondary.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            .disabled(selectedYear >= currentYear)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
    }
}

// Wheel Picker를 담은 Popover 컨텐츠
struct YearWheelPicker: View {
    @Binding var selectedYear: Int
    let minYear: Int
    let maxYear: Int
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempYear: Int
    
    // ⭐ 다국어 적용
    @Localized(.month_picker_select_year) var selectYearText
    @Localized(.month_picker_done) var doneText
    
    init(selectedYear: Binding<Int>, minYear: Int, maxYear: Int) {
        self._selectedYear = selectedYear
        self.minYear = minYear
        self.maxYear = maxYear
        self._tempYear = State(initialValue: selectedYear.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 타이틀
            Text(selectYearText)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.top, 16)
            
            // Wheel Picker
            Picker("", selection: $tempYear) {
                ForEach(minYear...maxYear, id: \.self) { year in
                    Text(verbatim: "\(year)")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .padding(.vertical, 8)
                        .tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 180)
            .clipped()
            
            // Done 버튼
            Button(action: {
                selectedYear = tempYear
                dismiss()
            }) {
                Text(doneText)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "00C896"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "00C896").opacity(0.1))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 200)
        .background(Color(.systemBackground))
    }
}
