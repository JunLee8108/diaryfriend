//
//  DetailedStatsCard.swift
//  DiaryFriend
//

import SwiftUI

struct DetailedStatsCard: View {
    let posts: [Post]
    
    @Localized(.stats_manual_or_ai) var headerText
    @Localized(.stats_manual_written) var manualWrittenText
    @Localized(.stats_ai_generated) var aiGeneratedText
    
    private var aiGeneratedCount: Int {
        posts.filter { $0.ai_generated == true }.count
    }
    
    private var manualCount: Int {
        posts.count - aiGeneratedCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header - Outside Card
            HStack {
                Text(headerText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .tracking(1.2)
                    .modernHighlight()  // ← 여기에 추가!
                
                Spacer()
            }
            
            // Card Content
            VStack(spacing: 12) {
                StatRow(
                    icon: "pencil.line",
                    iconColor: Color(hex: "00C896"),
                    title: manualWrittenText,
                    value: manualCount,
                    total: posts.count
                )
                
                StatRow(
                    icon: "cpu.fill",
                    iconColor: Color(hex: "00C896"),
                    title: aiGeneratedText,
                    value: aiGeneratedCount,
                    total: posts.count
                )
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
