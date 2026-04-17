//
//  OnboardingView.swift
//  DiaryFriend
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userProfileStore: UserProfileStore
    @EnvironmentObject var localizationManager: LocalizationManager

    @State private var displayName: String = ""
    @State private var selectedLanguage: Language = .english
    @State private var isSubmitting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isNameFieldFocused: Bool

    // Step 관리
    @State private var currentStep = 1
    @State private var selectedCharacter: CharacterWithAffinity?

    @StateObject private var characterStore = CharacterStore.shared

    // 시스템 언어 감지
    private var systemLanguage: String {
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        return langCode.starts(with: "ko") ? "ko" : "en"
    }

    private var localizedTexts: OnboardingTexts {
        systemLanguage == "ko" ? .korean : .english
    }

    private var step2Texts: OnboardingTexts {
        selectedLanguage == .korean ? .korean : .english
    }

    private var isKoreanSelected: Bool {
        selectedLanguage == .korean
    }

    var body: some View {
        ZStack {
            Color.modernBackground
                .ignoresSafeArea()
                .onTapGesture {
                    isNameFieldFocused = false
                }

            if currentStep == 1 {
                step1ProfileSetup
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
            } else {
                step2CharacterPick
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
        .onAppear {
            initializeDefaults()
        }
        .alert(localizedTexts.errorTitle, isPresented: $showError) {
            Button(localizedTexts.okButton, role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Step 1: Profile Setup

    private var step1ProfileSetup: some View {
        ScrollView {
            VStack(spacing: 40) {
                logoSection

                formSection

                // "Next" 버튼
                Button(action: {
                    isNameFieldFocused = false
                    let appLanguage: AppLanguage = (selectedLanguage == .korean) ? .korean : .english
                    localizationManager.setLanguage(appLanguage)
                    withAnimation {
                        currentStep = 2
                    }
                }) {
                    Text(localizedTexts.nextButton)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundColor(.white)
                        .background(isValid ? Color(hex: "00C896") : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isValid)
                .padding(.top, 8)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 40)
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                isNameFieldFocused = false
            }
        )
    }

    // MARK: - Step 2: Character Pick

    private var step2CharacterPick: some View {
        VStack(spacing: 0) {
            // 뒤로가기 버튼
            HStack {
                Button(action: {
                    withAnimation {
                        currentStep = 1
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text(step2Texts.backButton)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color(hex: "00C896"))
                    .padding(.vertical, 8)
                    .padding(.trailing, 16)
                    .contentShape(Rectangle())
                }
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 24) {
                    // 헤더
                    VStack(spacing: 12) {
                        Text(step2Texts.characterTitle)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)

                        // 악센트 도트 구분선
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color(hex: "00C896").opacity(0.3))
                                .frame(width: 24, height: 1.5)
                            Circle()
                                .fill(Color(hex: "00C896"))
                                .frame(width: 5, height: 5)
                            Rectangle()
                                .fill(Color(hex: "00C896").opacity(0.3))
                                .frame(width: 24, height: 1.5)
                        }

                        Text(step2Texts.characterSubtitle)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 30)

                    // 캐릭터 리스트
                    VStack(spacing: 0) {
                        ForEach(Array(characterStore.allCharacters.enumerated()), id: \.element.id) { index, character in
                            CharacterCard(
                                character: character,
                                onFollowToggle: {
                                    await characterStore.toggleFollowing(characterId: character.id)
                                },
                                index: index
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCharacter = character
                            }

                            if index < characterStore.allCharacters.count - 1 {
                                Divider()
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.modernSurfacePrimary)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 60)
            }
            .scrollIndicators(.hidden)

            // 하단 고정 버튼
            VStack(spacing: 0) {
                Button(action: {
                    Task {
                        await completeOnboarding()
                    }
                }) {
                    Group {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(step2Texts.getStartedButton)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundColor(.white)
                    .background(Color(hex: "00C896"))
                    .cornerRadius(12)
                }
                .disabled(isSubmitting)
                .padding(.horizontal, 30)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .background(
                Color.modernBackground
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
            )
        }
        .sheet(item: $selectedCharacter) { character in
            CharacterDetailSheet(
                character: character,
                onFollowToggle: {
                    await characterStore.toggleFollowing(characterId: character.id)
                    if let updated = characterStore.allCharacters.first(where: { $0.id == character.id }) {
                        selectedCharacter = updated
                    }
                }
            )
        }
        .task {
            if characterStore.allCharacters.isEmpty {
                await characterStore.loadAllCharacters()
            }
        }
    }

    // MARK: - Shared UI Components

    private var logoSection: some View {
        VStack(spacing: 16) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            Text(localizedTexts.title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
        .onTapGesture {
            isNameFieldFocused = false
        }
    }

    private var formSection: some View {
        VStack(spacing: 24) {
            nameInputSection
            languageSelectionSection
        }
    }

    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizedTexts.displayNameLabel)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .onTapGesture {
                        isNameFieldFocused = true
                    }

                TextField(localizedTexts.namePlaceholder, text: $displayName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .padding()
                    .autocapitalization(.words)
                    .disabled(isSubmitting)
                    .focused($isNameFieldFocused)
            }
            .frame(height: 52)

            if !isValidName && !displayName.isEmpty {
                Text(nameErrorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
        }
    }

    private var languageSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizedTexts.languageLabel)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            languageButton(.english)
            languageButton(.korean)
        }
    }

    private func languageButton(_ language: Language) -> some View {
        Button(action: {
            isNameFieldFocused = false
            selectedLanguage = language
        }) {
            HStack {
                Image(systemName: selectedLanguage == language ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedLanguage == language ? Color(hex: "00C896") : .gray)
                    .font(.system(size: 20))

                Text(language.displayName)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedLanguage == language ? Color(hex: "00C896") : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(isSubmitting)
    }

    // MARK: - Initialization

    private func initializeDefaults() {
        guard let profile = userProfileStore.userProfile else {
            print("⚠️ UserProfile not loaded in OnboardingView")
            return
        }

        if let name = profile.display_name, !name.isEmpty {
            displayName = name
        } else {
            displayName = extractFallbackName()
        }

        selectedLanguage = detectInitialLanguage(profileLanguage: profile.language)

        print("📋 Onboarding initialized:")
        print("   - System Language: \(systemLanguage)")
        print("   - Display Name: \(displayName)")
        print("   - Selected Language: \(selectedLanguage.rawValue)")
    }

    private func extractFallbackName() -> String {
        if let email = authService.currentUserEmail {
            let username = email.components(separatedBy: "@").first ?? "User"
            return username
        }
        return "User"
    }

    private func detectInitialLanguage(profileLanguage: String) -> Language {
        if systemLanguage == "ko" {
            return .korean
        }
        return Language(rawValue: profileLanguage) ?? .english
    }

    // MARK: - Validation

    private var isValidName: Bool {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count <= 30
    }

    private var isValid: Bool {
        isValidName
    }

    private var nameErrorMessage: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return localizedTexts.nameEmptyError
        } else if trimmed.count > 30 {
            return localizedTexts.nameTooLongError
        }
        return ""
    }

    // MARK: - Submit

    private func completeOnboarding() async {
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)

        guard isValid else {
            await MainActor.run {
                errorMessage = nameErrorMessage
                showError = true
            }
            return
        }

        await MainActor.run {
            isSubmitting = true
        }

        do {
            print("🚀 Starting onboarding completion...")

            try await userProfileStore.updateProfile(
                displayName: trimmedName,
                language: selectedLanguage.rawValue
            )
            print("✅ Profile updated")

            try await userProfileStore.completeOnboarding()
            print("✅ Onboarding marked complete")

            await MainActor.run {
                authService.isNewUser = false
            }

            // 온보딩 직후 알림 권한 요청
            NotificationManager.shared.hasRequestedPermission = true
            let granted = await NotificationManager.shared.requestPermission()
            if granted {
                NotificationManager.shared.scheduleDailyReminder(hour: 21, minute: 0)
            }

            print("🎉 Onboarding flow completed successfully")

        } catch {
            print("❌ Onboarding failed: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isSubmitting = false
            }
        }
    }
}

// MARK: - Onboarding Texts (시스템 언어 기반)
struct OnboardingTexts {
    let title: String
    let displayNameLabel: String
    let namePlaceholder: String
    let languageLabel: String
    let nextButton: String
    let getStartedButton: String
    let characterTitle: String
    let characterSubtitle: String
    let backButton: String
    let nameEmptyError: String
    let nameTooLongError: String
    let errorTitle: String
    let okButton: String

    static let english = OnboardingTexts(
        title: "Let's set up your profile",
        displayNameLabel: "Display Name",
        namePlaceholder: "Enter your name",
        languageLabel: "Language",
        nextButton: "Next",
        getStartedButton: "Get Started",
        characterTitle: "Follow Your AI Friends!",
        characterSubtitle: "Chat to write your diary, or they'll leave kind comments.",
        backButton: "Back",
        nameEmptyError: "Name cannot be empty",
        nameTooLongError: "Name must be 30 characters or less",
        errorTitle: "Error",
        okButton: "OK"
    )

    static let korean = OnboardingTexts(
        title: "프로필을 설정해주세요",
        displayNameLabel: "표시 이름",
        namePlaceholder: "이름을 입력하세요",
        languageLabel: "언어",
        nextButton: "다음",
        getStartedButton: "시작하기",
        characterTitle: "AI 친구들을 팔로우하세요",
        characterSubtitle: "대화를 통해 일기를 작성하거나 일기를 읽고 따뜻한 댓글을 남겨줘요",
        backButton: "뒤로",
        nameEmptyError: "이름은 비워둘 수 없습니다",
        nameTooLongError: "이름은 30자 이하여야 합니다",
        errorTitle: "오류",
        okButton: "확인"
    )
}

#Preview {
    OnboardingView()
        .environmentObject(AuthService())
        .environmentObject(UserProfileStore.shared)
        .environmentObject(LocalizationManager.shared)
}
