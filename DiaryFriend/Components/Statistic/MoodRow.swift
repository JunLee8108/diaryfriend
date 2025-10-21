//
//  MoodRow.swift
//  DiaryFriend
//

import SwiftUI

struct MoodRow: View {
    let icon: String
    let color: Color
    let mood: String
    let count: Int
    let maxCount: Int
    
    private var percentage: Double {
        guard maxCount > 0 else { return 0 }
        return Double(count) / Double(maxCount)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Weather Icon
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            // Mood Name
            Text(mood)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "00C896").opacity(0.7))
                        .frame(width: geometry.size.width * percentage)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)
                }
            }
            .frame(height: 6)
            
            // Count
            Text("\(count)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "00C896"))
                .frame(width: 32, alignment: .trailing)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        MoodRow(icon: "sun.max.fill", color: .secondary, mood: "Happy", count: 8, maxCount: 10)
        MoodRow(icon: "cloud.rain.fill", color: .secondary, mood: "Sad", count: 3, maxCount: 10)
        MoodRow(icon: "cloud.sun.fill", color: .secondary, mood: "Calm", count: 5, maxCount: 10)
    }
    .padding()
    .background(Color.modernBackground)
}
