//
//  PostMood.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/29/25.
//

import SwiftUI

// MARK: - Mood Selection Section

struct MoodSelectionSection: View {
    @Binding var selectedMood: Mood
    @State private var animateSelection = false
    
    // ⭐ 다국어 적용
    @Localized(.mood_selection_title) var selectionTitle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectionTitle)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
            
            HStack(spacing: 12) {
                ForEach(Mood.allCases) { mood in
                    MoodCard(
                        mood: mood,
                        isSelected: selectedMood == mood,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMood = mood
                            }
                            
                            // Haptic feedback
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Mood Card

struct MoodCard: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    // ⭐ View에서 직접 다국어 처리 (실시간 업데이트)
    private var moodTitle: String {
        switch mood {
        case .happy:
            return LocalizationManager.shared.localized(.mood_happy)
        case .sad:
            return LocalizationManager.shared.localized(.mood_sad)
        case .neutral:
            return LocalizationManager.shared.localized(.mood_neutral)
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: mood.weatherIcon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(mood.iconColor)
                    .symbolRenderingMode(.hierarchical)
                
                Text(moodTitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? mood.accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? mood.backgroundColor : Color.modernSurfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? mood.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(isSelected ? 0.08 : 0.04), radius: isSelected ? 12 : 8, y: 3)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
