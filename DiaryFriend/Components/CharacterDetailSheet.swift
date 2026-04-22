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
    
    // ✅ LocalizationManager 주입
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var isTogglingFollow = false
    @State private var displayedAffinity: Int = 0
    @State private var progressWidth: CGFloat = 0
    @State private var onlineStatus: OnlineStatus = .random
    @State private var animationTimer: Timer?
    @State private var scrollOffset: CGFloat = 0
    @State private var showAffinityHelp: Bool = false

    // Character image gallery
    @State private var galleryImages: [CharacterImage] = []
    @State private var currentImageIndex: Int = 0
    @State private var animatingSlideIndex: Int? = nil   // 해금 애니메이션 중인 슬라이드 tag
    
    // ✅ 언어별 표시 텍스트 계산
    private var isKorean: Bool {
        localizationManager.currentLanguage == .korean
    }
    
    private var displayName: String {
        character.localizedName(isKorean: isKorean)
    }
    
    private var displayDescription: String? {
        character.localizedDescription(isKorean: isKorean)
    }
    
    @Localized(.character_personality) var personalityLabel
    @Localized(.character_affinity_level) var affinityLabel
    @Localized(.character_about) var aboutLabel
    @Localized(.character_affinity_how_title) var affinityHowTitle
    @Localized(.character_affinity_how_body) var affinityHowBody

    // 전체 슬라이드 수: avatar_url 1장 + Character_Image N장
    private var totalSlideCount: Int { 1 + galleryImages.count }

    // 특정 슬라이드 인덱스의 해금 여부 (슬라이드 0 = avatar 는 항상 해금)
    private func isSlideUnlocked(at index: Int) -> Bool {
        if index == 0 { return true }
        let imageIdx = index - 1
        guard imageIdx < galleryImages.count else { return false }
        return character.affinity >= galleryImages[imageIdx].unlock_affinity
    }
    
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
            Color.clear
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView {
                    ZStack(alignment: .bottom) {
                        // Hero Image with Gradient
                        VStack(spacing: 0) {
                            ZStack(alignment: .bottom) {
                                // Character Image Gallery
                                // galleryImages 가 비어있으면 단일 이미지로 렌더 (TabView child 수 동적 변경 회피 → flash 방지).
                                // 로드 완료 후에만 TabView 로 전환해 avatar + gallery 슬라이드 전체를 한번에 구성.
                                // + Color.black baseline 으로 전환 중 시스템 기본 배경이 드러나는 flash 차단.
                                ZStack {
                                    Color.black   // sheet 배경이 전환 순간 비치는 flash 방지용 baseline

                                    Group {
                                        if galleryImages.isEmpty {
                                            AvatarHeroSlide(url: character.avatar_url)
                                        } else {
                                            TabView(selection: $currentImageIndex) {
                                                // 슬라이드 0 = 기본 avatar (항상 해금)
                                                AvatarHeroSlide(url: character.avatar_url)
                                                    .tag(0)

                                                // 슬라이드 1~N = Character_Image
                                                ForEach(Array(galleryImages.enumerated()), id: \.element.id) { idx, img in
                                                    GalleryImageSlide(
                                                        image: img,
                                                        isUnlocked: character.affinity >= img.unlock_affinity,
                                                        isAnimatingUnlock: animatingSlideIndex == idx + 1
                                                    )
                                                    .tag(idx + 1)
                                                }
                                            }
                                            .tabViewStyle(.page(indexDisplayMode: .never))
                                        }
                                    }
                                }
                                .transaction { $0.animation = nil }  // 구조 변경 시 모든 암시적 애니메이션 suppress
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
                                .allowsHitTesting(false)
                                
                                // Main Info Overlay
                                VStack(alignment: .leading, spacing: 16) {
                                    // Custom Page Indicator (이미지 2장 이상일 때만)
                                    if totalSlideCount > 1 {
                                        HStack {
                                            Spacer()
                                            GalleryPageIndicator(
                                                count: totalSlideCount,
                                                currentIndex: currentImageIndex,
                                                unlockedFlags: (0..<totalSlideCount).map { isSlideUnlocked(at: $0) }
                                            )
                                            Spacer()
                                        }
                                        .allowsHitTesting(false)
                                    }

                                    // Name
                                    Text(displayName)
                                        .font(.system(size: 25, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .allowsHitTesting(false)

                                    // Short Description
                                    if let description = displayDescription {
                                        Text(description)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineLimit(2)
                                            .lineSpacing(3)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .allowsHitTesting(false)
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
                                                        character.isFollowing
                                                            ? Color.white.opacity(0.18)   // Following = 유리 느낌
                                                            : Color(hex: "00C896")        // Follow = 밝은 브랜드 그린 CTA
                                                    )
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(
                                                                character.isFollowing
                                                                    ? Color.white.opacity(0.7)  // Following = 흰 테두리
                                                                    : Color.clear,              // Follow = 테두리 없음
                                                                lineWidth: character.isFollowing ? 1.5 : 0
                                                            )
                                                    )
                                                    .shadow(
                                                        color: character.isFollowing ? .clear : .black.opacity(0.15),
                                                        radius: character.isFollowing ? 0 : 4,
                                                        x: 0,
                                                        y: character.isFollowing ? 0 : 2
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
                                let localizedPersonalities = character.localizedPersonalities(isKorean: isKorean)
                                if !localizedPersonalities.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(hex: "9B59B6"))
                                            Text(personalityLabel)
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.primary)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 10) {
                                                ForEach(localizedPersonalities, id: \.self) { trait in
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
                                    .padding(.vertical, 20)
                                    
                                    Divider()
                                        .padding(.horizontal, 24)
                                }
                                
                                // Affinity Detail Section
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "FF6B6B"))
                                        Text(affinityLabel)
                                            .font(.system(size: 16, weight: .semibold))

                                        Button {
                                            showAffinityHelp.toggle()
                                        } label: {
                                            Image(systemName: "questionmark.circle")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .popover(isPresented: $showAffinityHelp) {
                                            AffinityHelpPopover(
                                                title: affinityHowTitle,
                                                message: affinityHowBody
                                            )
                                            .presentationCompactAdaptation(.popover)
                                        }
                                    }
                                    .foregroundColor(.primary)
                                    
                                    HStack(alignment: .center, spacing: 16) {
                                        Text("\(displayedAffinity)")
                                            .font(.system(size: 36, weight: .medium, design: .rounded))
                                            .foregroundColor(getAffinityColor(for: character.affinity))
                                            .animation(.none, value: displayedAffinity)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
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
                                .padding(.vertical, 20)
                                
                                Divider()
                                    .padding(.horizontal, 24)
                                
                                
                                
                                // About Section
                                if let description = displayDescription {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "text.alignleft")
                                                .font(.system(size: 14))
                                            Text(aboutLabel)
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.primary)
                                        
                                        Text(description)
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary.opacity(0.85))
                                            .lineSpacing(6)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 20)
                                }
                                
                                // Bottom padding
                                Color.clear
                                    .frame(height: 20)
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
        .task(id: character.id) {
            await loadGalleryAndDetectUnlocks()
        }
        .preferredColorScheme(nil)
        .statusBarHidden(false)
    }

    // MARK: - Gallery Load & Unlock Detection

    private func loadGalleryAndDetectUnlocks() async {
        // 1. 이미지 fetch (메모리 캐시 우선)
        let fetched = await CharacterStore.shared.loadImages(for: character.id)

        // 단일-이미지 → TabView 전환 시 UIPageViewController 의 implicit transition 을
        // 억제해 배경 flash 를 막는다.
        var txn = Transaction()
        txn.disablesAnimations = true
        withTransaction(txn) {
            galleryImages = fetched
        }

        guard !galleryImages.isEmpty else { return }

        // 2. 신규 해금 감지
        let lastSeen = character.lastSeenAffinity
        let newlyUnlocked = galleryImages
            .filter { $0.unlock_affinity > lastSeen && $0.unlock_affinity <= character.affinity }
            .sorted { $0.unlock_affinity > $1.unlock_affinity }   // 내림차순

        // 3. 최초 설치/로그인 직후 "폭탄" 방지: lastSeen == 0 이고 affinity 이미 ≥ 10 이면
        // 애니메이션 건너뛰고 조용히 acknowledge 만 한다.
        let isFreshUser = lastSeen == 0 && character.affinity >= 10

        if let latestUnlocked = newlyUnlocked.first,
           !isFreshUser,
           let imgIdx = galleryImages.firstIndex(where: { $0.id == latestUnlocked.id }) {

            let targetSlideIndex = imgIdx + 1  // avatar 슬롯 0 고려

            // 해당 슬라이드로 부드럽게 스크롤
            withAnimation(.easeInOut(duration: 0.5)) {
                currentImageIndex = targetSlideIndex
            }

            // 스크롤 완료 대기
            try? await Task.sleep(nanoseconds: 600_000_000)

            // 애니메이션 트리거
            animatingSlideIndex = targetSlideIndex

            // 애니메이션 완주 대기 (blur→clear ~1.4초)
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            animatingSlideIndex = nil
        }

        // 4. 3-tier write (memory + Realm + server)
        await CharacterStore.shared.acknowledgeUnlockedImages(
            characterId: character.id,
            currentAffinity: character.affinity
        )
    }
}

// Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Avatar Hero Slide (슬라이드 0 — 항상 해금)
private struct AvatarHeroSlide: View {
    let url: String?

    var body: some View {
        CachedAsyncImage(url: url, animateAppearance: false) {
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
    }
}

// MARK: - Gallery Image Slide (해금 이미지 슬라이드)
private struct GalleryImageSlide: View {
    let image: CharacterImage
    let isUnlocked: Bool
    let isAnimatingUnlock: Bool

    @Localized(.character_image_unlock_hint) private var unlockHintFormat

    @State private var blurRadius: CGFloat = 0
    @State private var lockOpacity: Double = 0
    @State private var flashOpacity: Double = 0

    var body: some View {
        ZStack {
            CachedAsyncImage(url: image.image_url, animateAppearance: false) {
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
            .blur(radius: blurRadius)

            // Dark overlay (잠긴 상태에서만 부분적으로)
            Color.black
                .opacity(isUnlocked ? 0 : 0.35 * lockOpacity)

            // Flash (해금 순간 번쩍)
            Color.white
                .opacity(flashOpacity)

            // Lock badge
            if lockOpacity > 0.01 {
                VStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)

                    Text(String(format: unlockHintFormat, image.unlock_affinity))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .opacity(lockOpacity)
                .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 2)
            }
        }
        .onAppear {
            syncToCurrentState(animated: false)
        }
        .onChange(of: isUnlocked) { _, _ in
            if !isAnimatingUnlock {
                syncToCurrentState(animated: true)
            }
        }
        .onChange(of: isAnimatingUnlock) { _, animating in
            if animating {
                performUnlockAnimation()
            }
        }
    }

    private func syncToCurrentState(animated: Bool) {
        let targetBlur: CGFloat = isUnlocked ? 0 : 24
        let targetLock: Double = isUnlocked ? 0 : 1.0
        if animated {
            withAnimation(.easeInOut(duration: 0.35)) {
                blurRadius = targetBlur
                lockOpacity = targetLock
            }
        } else {
            blurRadius = targetBlur
            lockOpacity = targetLock
        }
    }

    private func performUnlockAnimation() {
        // 잠긴 상태에서 시작
        blurRadius = 24
        lockOpacity = 1.0
        flashOpacity = 0

        // 0.3초 pause → flash 번쩍 → blur/lock 동시 해제
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.25)) {
                flashOpacity = 0.55
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeOut(duration: 0.4)) {
                    flashOpacity = 0
                }
                withAnimation(.easeOut(duration: 0.8)) {
                    blurRadius = 0
                    lockOpacity = 0
                }
            }
        }
    }
}

// MARK: - Gallery Page Indicator
private struct GalleryPageIndicator: View {
    let count: Int
    let currentIndex: Int
    let unlockedFlags: [Bool]

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { idx in
                let isUnlocked = idx < unlockedFlags.count ? unlockedFlags[idx] : false
                let isCurrent = idx == currentIndex

                Circle()
                    .fill(isUnlocked ? Color.white : Color.clear)
                    .frame(
                        width: isCurrent ? 10 : 8,
                        height: isCurrent ? 10 : 8
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                Color.white.opacity(isUnlocked ? 0 : 0.6),
                                lineWidth: 1
                            )
                    )
                    .opacity(isCurrent ? 1.0 : 0.65)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
            }
        }
    }
}

// MARK: - Affinity Help Popover
private struct AffinityHelpPopover: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "FF6B6B"))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(width: 260)
    }
}
