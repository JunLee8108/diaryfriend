//
//  MoodDistributionCard.swift
//  DiaryFriend
//

import SwiftUI

struct MoodDistributionCard: View {
    let posts: [Post]
    
    private var moodCounts: [(mood: String, count: Int, icon: String, color: Color)] {
        let moodDict = Dictionary(grouping: posts.compactMap { $0.mood }) { $0 }
            .mapValues { $0.count }
        
        // 날씨 기반 아이콘 및 색상 매핑
        let moodWeatherData: [String: (icon: String, color: Color)] = [
            "happy": ("sun.max.fill", .yellow),
            "sad": ("cloud.rain.fill", Color(hex:"1CA3DE")),
            "calm": ("cloud.sun.fill", .cyan),
            "excited": ("sun.and.horizon.fill", .orange),
            "angry": ("cloud.bolt.fill", .red),
            "anxious": ("wind", .purple),
            "grateful": ("sunrise.fill", .pink),
            "tired": ("moon.stars.fill", .indigo),
            "lonely": ("cloud.fog.fill", .gray),
            "proud": ("sparkles", .yellow),
            "neutral": ("cloud", .secondary)
        ]
        
        return moodDict.map {
            let weatherData = moodWeatherData[$0.key.lowercased()] ?? ("cloud", .secondary)
            return (
                mood: $0.key,
                count: $0.value,
                icon: weatherData.icon,
                color: weatherData.color
            )
        }
        .sorted { $0.count > $1.count }
    }
    
    private var maxCount: Int {
        moodCounts.max(by: { $0.count < $1.count })?.count ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header - Outside Card
            HStack {
                Text("MOOD STATS")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .tracking(1.2)
                    .modernHighlight()  // ← 여기에 추가!
                
                Spacer()
            }
            
            // Card Content
            VStack(alignment: .leading, spacing: 16) {
                if moodCounts.isEmpty {
                    Text("No mood data available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 12) {
                        ForEach(moodCounts.prefix(5), id: \.mood) { item in
                            MoodRow(
                                icon: item.icon,
                                color: item.color,
                                mood: item.mood.capitalized,
                                count: item.count,
                                maxCount: maxCount
                            )
                        }
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
