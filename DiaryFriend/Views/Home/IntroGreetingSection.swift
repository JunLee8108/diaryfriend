//
//  IntroGreetingSection.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/24/25.
//

import SwiftUI

// MARK: - Intro Greeting Section
struct IntroGreetingSection: View {
    // Self-managed animation states
    @State private var introAnimated = false
    @State private var statsAnimated = false
    
    // Scene phase detection for foreground/background transitions
    @Environment(\.scenePhase) var scenePhase
    
    // Current date for time-based greeting calculation
    @State private var currentDate = Date()
    
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var dataStore = DataStore.shared
    
    // ⭐ 시간대별 인사말 (다국어 적용)
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        switch hour {
        case 5..<12:
            return LocalizationManager.shared.localized(.greeting_morning)
        case 12..<17:
            return LocalizationManager.shared.localized(.greeting_afternoon)
        case 17..<22:
            return LocalizationManager.shared.localized(.greeting_evening)
        default:
            return LocalizationManager.shared.localized(.greeting_night)
        }
    }
    
    // Time-based emoji
    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        switch hour {
        case 5..<12:
            return "☀️"
        case 12..<17:
            return "🌤"
        case 17..<22:
            return "🌙"
        default:
            return "🌙"
        }
    }
    
    // ⭐ 다국어 레이블
    @Localized(.intro_stats_streak) var streakLabel
    @Localized(.intro_stats_this_month) var monthLabel
    
    var body: some View {
        VStack(spacing: 30) {
            // Greeting header
            HStack(spacing: 8) {
                Text("\(greeting), \(profileStore.currentDisplayName)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(greetingEmoji)
                    .font(.system(size: 17))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(introAnimated ? 1 : 0)
            .offset(y: introAnimated ? 0 : 10)
            
            // ⭐ Compact Stats Row
            if !dataStore.isLoading {
                HStack(spacing: 16) {
                    // Streak
                    CompactStatView(
                        icon: "flame.fill",
                        value: dataStore.currentStreak,
                        label: streakLabel,
                        color: Color(hex: "FF6961"),
                        animated: statsAnimated
                    )
                    
                    // Divider
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 4, height: 4)
                        .opacity(statsAnimated ? 1 : 0)
                    
                    // This month
                    CompactStatView(
                        icon: "square.and.pencil",
                        value: dataStore.currentMonthPostCount,
                        label: monthLabel,
                        color: Color(hex: "00C896"),
                        animated: statsAnimated
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(statsAnimated ? 1 : 0)
                .offset(y: statsAnimated ? 0 : 10)
            }
        }
        .onAppear {
            playAnimation()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Update current time when app becomes active
                currentDate = Date()
                
                // Replay animation only when returning from background
                if oldPhase == .background {
                    playAnimation()
                }
            }
        }
    }
    
    // MARK: - Animation Helper
    private func playAnimation() {
        // Reset animation states
        introAnimated = false
        statsAnimated = false
        
        // Sequential animations
        withAnimation(.easeOut(duration: 0.6)) {
            introAnimated = true
        }
        
        // Stats row
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            statsAnimated = true
        }
    }
}

// MARK: - Compact Stat View (한 줄 인라인 스타일)
struct CompactStatView: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color
    let animated: Bool
    
    @State private var displayValue: Double = 0
    
    var body: some View {
        HStack(spacing: 6) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            // Value
            Text("\(Int(displayValue))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .contentTransition(.numericText(value: displayValue))
            
            // Label
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .onChange(of: animated) { _, isAnimated in
            if isAnimated {
                withAnimation(.spring(duration: 0.8, bounce: 0.2)) {
                    displayValue = Double(value)
                }
            }
        }
        .onAppear {
            if animated {
                withAnimation(.spring(duration: 0.8, bounce: 0.2)) {
                    displayValue = Double(value)
                }
            } else {
                displayValue = Double(value)
            }
        }
    }
}
