//
//  DetailedStatsCard.swift
//  DiaryFriend
//

import SwiftUI

struct DetailedStatsCard: View {
    let posts: [Post]
    
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
                Text("MANUAL or AI")
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
                    title: "Manual Written",
                    value: manualCount,
                    total: posts.count
                )
                
                StatRow(
                    icon: "cpu.fill",
                    iconColor: Color(hex: "00C896"),
                    title: "AI Generated",
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
