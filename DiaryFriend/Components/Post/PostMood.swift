//
//  PostMood.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/29/25.
//

// Views/Post/Components/PostMood.swift

import SwiftUI

// MARK: - Mood Selection Section

struct MoodSelectionSection: View {
    @Binding var selectedMood: Mood
    @State private var animateSelection = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How are you feeling?")
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
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: mood.weatherIcon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(mood.iconColor)
                    .symbolRenderingMode(.hierarchical)
                
                Text(mood.title)
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
