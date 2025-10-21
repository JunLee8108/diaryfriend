//
//  MonthCell.swift
//  DiaryFriend
//

import SwiftUI

struct MonthCell: View {
    let monthName: String
    let isSelected: Bool      // 선택된 월
    let isCurrent: Bool       // ⭐ 추가: 오늘 날짜의 월
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(monthName)
                .font(.system(size: 16, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color(hex: "00C896") : Color.modernSurfacePrimary)
                        .shadow(
                            color: isSelected ? Color(hex: "00C896").opacity(0.4) : .black.opacity(0.04),
                            radius: isSelected ? 12 : 6,
                            x: 0,
                            y: isSelected ? 6 : 3
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ? Color.white.opacity(0.2) :           // 선택됨: 흰색 테두리
                            isCurrent ? Color(hex: "00C896") :                // ⭐ 오늘: teal 테두리
                            Color.clear,                                       // 기본: 테두리 없음
                            lineWidth: isSelected ? 2 : (isCurrent ? 2 : 0)   // ⭐ 테두리 두께
                        )
                )
        }
    }
}
