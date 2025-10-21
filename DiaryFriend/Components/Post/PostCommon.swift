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
    
    var title: String {
        switch self {
        case .neutral: return "Neutral"
        case .happy: return "Happy"
        case .sad: return "Sad"
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
