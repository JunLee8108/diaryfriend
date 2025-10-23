//
//  PostCommon.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/29/25.
//

// Views/Post/Components/PostCommon.swift

import SwiftUI

// MARK: - Mood Enum

enum Mood: String, CaseIterable, Identifiable {
    case neutral = "neutral"
    case happy = "happy"
    case sad = "sad"
    
    var id: String { rawValue }
    
    var weatherIcon: String {
        switch self {
        case .neutral: return "cloud"
        case .happy: return "sun.max"
        case .sad: return "cloud.rain"
        }
    }
    
    // ⭐ title 제거 또는 deprecated
    @available(*, deprecated, message: "Use localizedTitle() in View instead")
    var title: String {
        // fallback만 제공
        switch self {
        case .neutral: return "Neutral"
        case .happy: return "Happy"
        case .sad: return "Sad"
        }
    }
    
    // ⭐ 데이터 표시용 아이콘 추가
    var filledIcon: String {
        switch self {
        case .neutral: return "cloud"
        case .happy: return "sun.max.fill"
        case .sad: return "cloud.rain.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .neutral: return Color(hex: "F5F5F5")
        case .happy: return Color(hex: "FFF9E6")
        case .sad: return Color(hex: "E6F3FF")
        }
    }
    
    var accentColor: Color {
        switch self {
        case .neutral: return Color(hex: "6E6E6E")
        case .happy: return Color(hex: "FF8C00")
        case .sad: return Color(hex: "1E90FF")
        }
    }
    
    var iconColor: Color {
        switch self {
        case .neutral: return Color(hex: "757575")
        case .happy: return Color(hex: "FF8C00")
        case .sad: return Color(hex: "1E90FF")
        }
    }
    
    // ⭐ String에서 Mood로 변환
    static func from(_ moodString: String?) -> Mood {
        guard let moodString = moodString?.lowercased() else {
            return .neutral
        }
        return Mood(rawValue: moodString) ?? .neutral
    }
}

// MARK: - Header Section

struct HeaderSection: View {
    let dateTitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                
                Text(dateTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
    }
}
