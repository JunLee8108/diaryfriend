//
//  StatisticsLoadingView.swift
//  DiaryFriend
//

import SwiftUI

struct StatisticsLoadingView: View {
    var body: some View {
        VStack(spacing: 25) {
            skeletonMonthOverview
            skeletonDetailedStats
            skeletonMoodDistribution
            skeletonCalendar
        }
    }
    
    // MARK: - Month Overview Skeleton
    
    private var skeletonMonthOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ShimmeringRectangle(cornerRadius: 6, height: 16)
                    .frame(width: 100)
                Spacer()
            }
            
            // Card Content
            VStack(alignment: .leading, spacing: 16) {
                // Main Stats - Centered
                HStack {
                    Spacer()
                    
                    VStack(spacing: 4) {
                        ShimmeringRectangle(cornerRadius: 10, height: 40)
                            .frame(width: 80)
                        
                        ShimmeringRectangle(cornerRadius: 6, height: 16)
                            .frame(width: 50)
                    }
                    
                    Spacer()
                }
                
                // Progress Bar Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ShimmeringRectangle(cornerRadius: 6, height: 12)
                            .frame(width: 120)
                        
                        Spacer()
                        
                        ShimmeringRectangle(cornerRadius: 6, height: 12)
                            .frame(width: 40)
                    }
                    
                    ShimmeringRectangle(cornerRadius: 8, height: 12)
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
    
    // MARK: - Detailed Stats Skeleton
    
    private var skeletonDetailedStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ShimmeringRectangle(cornerRadius: 6, height: 16)
                    .frame(width: 120)
                Spacer()
            }
            
            // Card Content
            VStack(spacing: 12) {
                skeletonStatRow
                skeletonStatRow
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.modernSurfacePrimary)
                    .shadow(color: .black.opacity(0.03), radius: 12, x: 0, y: 4)
            )
        }
    }
    
    private var skeletonStatRow: some View {
        HStack(spacing: 12) {
            ShimmeringCircle(size: 24)
            
            ShimmeringRectangle(cornerRadius: 6, height: 14)
                .frame(width: 100)
            
            Spacer()
            
            HStack(spacing: 8) {
                ShimmeringRectangle(cornerRadius: 6, height: 16)
                    .frame(width: 30)
                
                ShimmeringRectangle(cornerRadius: 6, height: 12)
                    .frame(width: 45)
            }
        }
    }
    
    // MARK: - Mood Distribution Skeleton
    
    private var skeletonMoodDistribution: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ShimmeringRectangle(cornerRadius: 6, height: 16)
                    .frame(width: 100)
                Spacer()
            }
            
            // Card Content
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        skeletonMoodRow
                    }
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
    
    private var skeletonMoodRow: some View {
        HStack(spacing: 12) {
            ShimmeringCircle(size: 24)
            
            ShimmeringRectangle(cornerRadius: 6, height: 14)
                .frame(width: 80)
            
            ShimmeringRectangle(cornerRadius: 6, height: 6)
                .frame(maxWidth: .infinity)
            
            ShimmeringRectangle(cornerRadius: 6, height: 14)
                .frame(width: 32)
        }
    }
    
    // MARK: - Calendar Skeleton
    
    private var skeletonCalendar: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ShimmeringRectangle(cornerRadius: 6, height: 16)
                    .frame(width: 110)
                Spacer()
            }
            
            // Card Content
            VStack(alignment: .leading, spacing: 16) {
                // Weekday Header (실제 텍스트 표시)
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { index in
                        let days = ["S", "M", "T", "W", "T", "F", "S"]
                        Text(days[index])
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 8)
                
                // Calendar Grid
                let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<42, id: \.self) { _ in
                        ShimmeringCircle(size: 32)
                    }
                }
                
                // Legend
                HStack(spacing: 20) {
                    Spacer()
                    
                    HStack(spacing: 6) {
                        ShimmeringCircle(size: 12)
                        ShimmeringRectangle(cornerRadius: 4, height: 11)
                            .frame(width: 50)
                    }
                    
                    HStack(spacing: 6) {
                        ShimmeringCircle(size: 12)
                        ShimmeringRectangle(cornerRadius: 4, height: 11)
                            .frame(width: 35)
                    }
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

#Preview {
    ScrollView {
        StatisticsLoadingView()
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .padding(.bottom, 40)
    }
    .background(Color.modernBackground)
}
