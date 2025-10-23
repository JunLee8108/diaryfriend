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
    @State private var streakAnimated = false
    
    // Scene phase detection for foreground/background transitions
    @Environment(\.scenePhase) var scenePhase
    
    // Current date for time-based greeting calculation
    @State private var currentDate = Date()
    
    @ObservedObject private var profileStore = UserProfileStore.shared
    
    // ⭐ Time-based greeting (다국어 적용)
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
    
    var body: some View {
        VStack(spacing: 20) {
            // Main greeting card
            VStack(alignment: .leading, spacing: 16) {
                // Greeting header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("\(greeting), \(profileStore.currentDisplayName)")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(greetingEmoji)
                                .font(.system(size: 20))
                        }
                        .opacity(introAnimated ? 1 : 0)
                        .offset(y: introAnimated ? 0 : 10)
                    }
                }
            }
            .padding(20)
            .scaleEffect(introAnimated ? 1 : 0.95)
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
        streakAnimated = false
        
        // Sequential animations
        withAnimation(.easeOut(duration: 0.6)) {
            introAnimated = true
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            streakAnimated = true
        }
    }
}
