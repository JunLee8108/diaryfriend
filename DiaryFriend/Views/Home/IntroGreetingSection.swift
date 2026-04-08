//
//  IntroGreetingSection.swift
//  DiaryFriend
//

import SwiftUI

// MARK: - Intro Greeting Section (Soft & Cozy Hero Card)
struct IntroGreetingSection: View {
    @State private var introAnimated = false
    @Environment(\.scenePhase) var scenePhase
    @State private var currentDate = Date()
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var characterStore = CharacterStore.shared

    // ⭐ 다국어 인사
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

    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        switch hour {
        case 5..<12:  return "☀️"
        case 12..<17: return "🌤"
        case 17..<22: return "🌙"
        default:       return "✨"
        }
    }

    private var subMessage: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        switch hour {
        case 5..<12:
            return LocalizationManager.shared.currentLanguage == .korean
                ? "오늘 하루도 기록해볼까요?" : "Ready to write your story today?"
        case 12..<17:
            return LocalizationManager.shared.currentLanguage == .korean
                ? "오늘은 어떤 하루를 보내고 있나요?" : "How's your day going so far?"
        case 17..<22:
            return LocalizationManager.shared.currentLanguage == .korean
                ? "오늘 하루를 돌아볼 시간이에요" : "Time to reflect on your day"
        default:
            return LocalizationManager.shared.currentLanguage == .korean
                ? "오늘 하루는 어땠나요?" : "How was your day?"
        }
    }

    /// 팔로우 중인 첫 번째 캐릭터 아바타 URL
    private var avatarURL: String? {
        characterStore.followingCharacters.first?.avatar_url
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 상단: 아바타 + 인사말
            HStack(spacing: 12) {
                // AI 캐릭터 아바타
                if let urlString = avatarURL {
                    CachedAsyncImage(url: urlString) {
                        Circle()
                            .fill(Color.brandBlush)
                            .overlay(
                                Text("🧸")
                                    .font(.system(size: 20))
                            )
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.brandLight, lineWidth: 2)
                    )
                } else {
                    Circle()
                        .fill(Color.brandBlush)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text("🧸")
                                .font(.system(size: 22))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.brandLight, lineWidth: 2)
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("\(greeting), \(profileStore.currentDisplayName)")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        Text(greetingEmoji)
                            .font(.system(size: 18))
                    }

                    Text(subMessage)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.brandBlush.opacity(0.5), Color.modernSurfacePrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.brand.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .opacity(introAnimated ? 1 : 0)
        .offset(y: introAnimated ? 0 : 8)
        .scaleEffect(introAnimated ? 1 : 0.97)
        .onAppear { playAnimation() }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                currentDate = Date()
                if oldPhase == .background { playAnimation() }
            }
        }
    }

    private func playAnimation() {
        introAnimated = false
        withAnimation(.easeOut(duration: 0.5)) {
            introAnimated = true
        }
    }
}
