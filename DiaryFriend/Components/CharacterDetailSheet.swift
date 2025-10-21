//  CharacterDetailSheet.swift
//  DiaryFriend
//
//  캐릭터 상세 모달 - Clean Minimal 디자인
//

import SwiftUI

// Online Status Enum
enum OnlineStatus: CaseIterable {
    case online
    case away
    case offline
    
    var title: String {
        switch self {
        case .online: return "Online"
        case .away: return "Away"
        case .offline: return "Offline"
        }
    }
    
    var color: Color {
        switch self {
        case .online: return Color.green
        case .away: return Color.orange
        case .offline: return Color.gray
        }
    }
    
    static var random: OnlineStatus {
        allCases.randomElement() ?? .offline
    }
}

struct CharacterDetailSheet: View {
    let character: CharacterWithAffinity
    let onFollowToggle: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isTogglingFollow = false
    @State private var displayedAffinity: Int = 0
    @State private var progressWidth: CGFloat = 0
    @State private var onlineStatus: OnlineStatus = .random
    @State private var animationTimer: Timer?
    @State private var scrollOffset: CGFloat = 0
    
    // Pastel tone color palette
    func getAffinityColor(for value: Int) -> Color {
        switch value {
        case 0..<10:
            return Color(hex: "#B0B0B0")  // 쿨 그레이
        case 10..<20:
            return Color(hex: "#A8D8EA")  // 연한 스카이
        case 20..<30:
            return Color(hex: "#FFE66D")  // 소프트 옐로우
        case 30..<40:
            return Color(hex: "#FFD93D")  // 선샤인 옐로우
        case 40..<50:
            return Color(hex: "#FFBC42")  // 골든 오렌지
        case 50..<60:
            return Color(hex: "#FF9A56")  // 따뜻한 오렌지
        case 60..<70:
            return Color(hex: "#FF8066")  // 코랄 오렌지
        case 70..<80:
            return Color(hex: "#FF6B6B")  // 소프트 레드
        case 80..<90:
            return Color(hex: "#EE5A6F")  // 딥 로즈
        case 90...100:
            return Color(hex: "#E63946")  // 패션 레드
        default:
            return Color(hex: "#B0B0B0")  // 쿨 그레이
        }
    }
    
    func getAffinityColors(for value: Int) -> [Color] {
        let baseColor = getAffinityColor(for: value)
        return [baseColor.opacity(0.8), baseColor, baseColor.opacity(0.9)]
    }
    
    // Counting animation function
    func startCountingAnimation() {
        let targetValue = character.affinity
        let duration = 0.6
        let updateInterval = 0.016
        let totalSteps = Int(duration / updateInterval)
        
        animationTimer?.invalidate()
        displayedAffinity = 0
        progressWidth = 0
        
        var currentStep = 0
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            currentStep += 1
            
            if currentStep <= totalSteps {
                let linearProgress = Double(currentStep) / Double(totalSteps)
                let easedProgress = 1 - pow(1 - linearProgress, 2)
                let newValue = Int((Double(targetValue) * easedProgress).rounded())
                displayedAffinity = min(newValue, targetValue)
            } else {
                displayedAffinity = targetValue
                timer.invalidate()
                animationTimer = nil
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.black
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView {
                    ZStack(alignment: .bottom) {
                        // Hero Image with Gradient
                        VStack(spacing: 0) {
                            ZStack(alignment: .bottom) {
                                // Character Image
                                CachedAsyncImage(url: character.avatar_url) {
                                    Rectangle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray.opacity(0.3),
                                                Color.gray.opacity(0.1)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ))
                                        .overlay(ProgressView().tint(.white))
                                }
                                .frame(maxWidth: min(geometry.size.width, 700))
                                .frame(height: max(500, geometry.size.height * 0.6))
                                .clipped()
                                .offset(y: scrollOffset > 0 ? -scrollOffset * 0.5 : 0)
                                .scaleEffect(scrollOffset > 0 ? 1 + (scrollOffset / 1000) : 1)
                                
                                // Long Gradient Overlay
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: .clear, location: 0.3),
                                        .init(color: .black.opacity(0.2), location: 0.5),
                                        .init(color: .black.opacity(0.5), location: 0.7),
                                        .init(color: .black.opacity(0.8), location: 0.85),
                                        .init(color: Color(UIColor.systemBackground), location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(maxWidth: min(geometry.size.width, 700))
                                .frame(height: 450)
                                
                                // Main Info Overlay
                                VStack(alignment: .leading, spacing: 16) {
                                    // Name
                                    Text(character.name)
                                        .font(.system(size: 25, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    // Short Description
                                    if let description = character.description {
                                        Text(description)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineLimit(2)
                                            .lineSpacing(3)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    
                                    // Follow Button
                                    HStack {
                                        Spacer()
                                        
                                        Button(action: {
                                            Task {
                                                isTogglingFollow = true
                                                await onFollowToggle()
                                                isTogglingFollow = false
                                            }
                                        }) {
                                            Group {
                                                if isTogglingFollow {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                } else {
                                                    Text(character.isFollowing ? "Following ✓" : "Follow +")
                                                        .font(.system(size: 13, weight: .semibold))
                                                }
                                            }
                                            .foregroundColor(.white)
                                            .frame(width: 105, height: 32)  // 고정 크기
                                            .background(
                                                Capsule()
                                                    .fill(
                                                        character.isFollowing ?
                                                            Color(hex:"00A077") :                    // Following = 진한 초록
                                                        Color.secondary.opacity(0.5)         // Follow + = 50% 초록 (secondary 느낌)
                                                    )
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(
                                                                character.isFollowing ?
                                                                    Color.clear :                     // Following = 테두리 없음
                                                                Color.secondary.opacity(0.6), // Follow + = 초록 테두리
                                                                lineWidth: 1
                                                            )
                                                    )
                                            )
                                        }
                                        .disabled(isTogglingFollow)
                                    }
                                    .padding(.top, 4)
                                }
                                .frame(maxWidth: min(geometry.size.width, 700) - 48)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 32)
                            }
                            .frame(height: max(500, geometry.size.height * 0.6))
                            
                            // Detail Sections
                            VStack(alignment: .leading, spacing: 0) {
                                // Personality Section
                                if let personalities = character.personality, !personalities.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 14))
                                            Text("Personality")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.primary)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 10) {
                                                ForEach(personalities, id: \.self) { trait in
                                                    Text(trait)
                                                        .font(.system(size: 13, weight: .medium))
                                                        .padding(.horizontal, 14)
                                                        .padding(.vertical, 8)
                                                        .background(
                                                            Capsule()
                                                                .fill(Color(.gray).opacity(0.12))
                                                        )
                                                        .foregroundColor(Color.primary)
                                                }
                                            }
                                            .padding(.horizontal, 24)
                                        }
                                        .padding(.horizontal, -24)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 28)
                                    
                                    Divider()
                                        .padding(.horizontal, 24)
                                }
                                
                                // Affinity Detail Section
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(getAffinityColor(for: character.affinity))
                                        Text("Affinity Level")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.primary)
                                    
                                    HStack(alignment: .center, spacing: 16) {
                                        Text("\(displayedAffinity)")
                                            .font(.system(size: 35, weight: .medium, design: .rounded))
                                            .foregroundColor(getAffinityColor(for: character.affinity))
                                            .animation(.none, value: displayedAffinity)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("out of 100")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                            
                                            // Progress Bar
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(Color.gray.opacity(0.15))
                                                        .frame(height: 12)
                                                    
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(LinearGradient(
                                                            gradient: Gradient(colors: getAffinityColors(for: character.affinity)),
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        ))
                                                        .frame(width: progressWidth, height: 12)
                                                        .onAppear {
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                                withAnimation(.easeOut(duration: 0.6)) {
                                                                    progressWidth = geo.size.width * (Double(character.affinity) / 100.0)
                                                                }
                                                            }
                                                        }
                                                }
                                            }
                                            .frame(height: 12)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 28)
                                
                                Divider()
                                    .padding(.horizontal, 24)
                                
                               
                                
                                // About Section
                                if let description = character.description {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "text.alignleft")
                                                .font(.system(size: 14))
                                            Text("About")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.primary)
                                        
                                        Text(description)
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary.opacity(0.85))
                                            .lineSpacing(6)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 28)
                                }
                                
                                // Bottom padding
                                Color.clear
                                    .frame(height: 40)
                            }
                            .background(Color(UIColor.systemBackground))
                        }
                        .background(
                            GeometryReader { scrollGeo in
                                Color.clear
                                    .preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: scrollGeo.frame(in: .named("scroll")).minY
                                    )
                            }
                        )
                    }
                    .frame(maxWidth: min(geometry.size.width, 700))
                    .frame(maxWidth: .infinity)
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
                .ignoresSafeArea(edges: .top)
            }
            
            // Top Overlay Buttons
            HStack {
                // Online Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(onlineStatus.color)
                        .frame(width: 8, height: 8)
                    
                    Text(onlineStatus.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.4))
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                )
                
                Spacer()
                
                // Close button
                Button(action: {
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 48)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                startCountingAnimation()
            }
        }
        .onDisappear {
            animationTimer?.invalidate()
            animationTimer = nil
        }
        .preferredColorScheme(nil)
        .statusBarHidden(false)
    }
}

// Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
