//
//  StatisticsEmptyStateCard.swift
//  DiaryFriend
//

import SwiftUI

struct StatisticsEmptyStateCard: View {
    let month: Date
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: month)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No entries in \(monthName)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Start writing to see your statistics!")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.modernSurfacePrimary)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        )
    }
}

#Preview {
    StatisticsEmptyStateCard(month: Date())
        .padding()
        .background(Color.modernBackground)
}
