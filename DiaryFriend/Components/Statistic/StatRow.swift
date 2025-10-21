//
//  StatRow.swift
//  DiaryFriend
//

import SwiftUI

struct StatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: Int
    let total: Int
    
    private var percentage: Double {
        total == 0 ? 0 : Double(value) / Double(total)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(value)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(iconColor)
                    .contentTransition(.numericText())
                
                Text("(\(Int(percentage * 100))%)")
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
        }
    }
}
