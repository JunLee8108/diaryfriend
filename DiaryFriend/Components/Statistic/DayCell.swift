//
//  DayCell.swift
//  DiaryFriend
//

import SwiftUI

struct DayCell: View {
    let day: Int
    let hasPost: Bool
    let isToday: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(hasPost ? Color(hex: "00C896") : Color.secondary.opacity(0.15))
            
            if isToday {
                Circle()
                    .strokeBorder(Color(hex: "FF7AB2"), lineWidth: 2)
            }
            
            Text("\(day)")
                .font(.system(size: 12, weight: hasPost ? .bold : .regular))
                .foregroundColor(hasPost ? .white : .secondary)
        }
        .frame(height: 32)
    }
}

#Preview {
    HStack(spacing: 16) {
        DayCell(day: 1, hasPost: false, isToday: false)
        DayCell(day: 15, hasPost: true, isToday: false)
        DayCell(day: 20, hasPost: true, isToday: true)
        DayCell(day: 25, hasPost: false, isToday: true)
    }
    .padding()
    .background(Color.modernBackground)
}
