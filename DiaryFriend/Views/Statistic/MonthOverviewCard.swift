//
//  MonthOverviewCard.swift
//  DiaryFriend
//

import SwiftUI

struct MonthOverviewCard: View {
    let posts: [Post]
    let selectedMonth: Date
    
    private var postCount: Int {
        posts.count
    }
    
    private var daysInMonth: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: selectedMonth)
        return range?.count ?? 30
    }
    
    private var writingPercentage: Double {
        let writingDays = Set(posts.map { $0.entry_date }).count
        guard daysInMonth > 0 else { return 0 }
        return Double(writingDays) / Double(daysInMonth)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header - Outside Card
            HStack {
                Text("THIS MONTH")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .tracking(1.2)
                        .modernHighlight()  // ← 여기에 추가!
                
                Spacer()
            }
            
            // Card Content
            VStack(alignment: .leading, spacing: 16) {
                // Main Stats - Centered
                HStack {
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(postCount)")
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "00C896"))
                            .contentTransition(.numericText())
                        
                        Text("Posts")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Writing Frequency")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(writingPercentage * 100))%")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "00C896"))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                            
                            // Progress with gradient
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "00C896"),
                                            Color(hex: "89dfbc")
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * writingPercentage)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: writingPercentage)
                        }
                    }
                    .frame(height: 12)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.modernSurfacePrimary)
                    .shadow(color: .black.opacity(0.03), radius: 12, x: 0, y: 4)
            )
        }
    }
}
