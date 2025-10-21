//
//  PostAI.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/29/25.
//

// Views/Post/Components/PostAI.swift

import SwiftUI

// MARK: - AI Comment Toggle Section

struct AICommentToggleSection: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "00C896"))
                    
                    Text("AI Insights")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Text("Get thoughtful AI feedback on your entry")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "00C896")))
                .scaleEffect(0.9)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.modernSurfacePrimary)
                .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - No Following Characters Section

struct NoFollowingCharactersSection: View {
    let onNavigateToProfile: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Disabled AI Toggle UI
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("AI Insights")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    Text("Get thoughtful AI feedback on your entry")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.gray.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(false))
                    .toggleStyle(SwitchToggleStyle(tint: .gray))
                    .scaleEffect(0.9)
                    .disabled(true)
                    .opacity(0.5)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.modernSurfacePrimary.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
            .opacity(0.8)
            
            // Simplified Guide Message & Button
            Text("Follow a character to enable AI insights")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary.opacity(0.8))
                .padding(.top, 10)
            
            Button(action: onNavigateToProfile) {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("Find Characters")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "00A077"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "00A077"), lineWidth: 1)
                        )
                )
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 24)
    }
}
