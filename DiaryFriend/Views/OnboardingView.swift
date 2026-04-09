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
    
    // ⭐ 시스템 언어 감지 (LocalizationManager와 독립)
    private var systemLanguage: String {
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        return langCode.starts(with: "ko") ? "ko" : "en"
    }
    
    // ⭐ 시스템 언어 기반 텍스트 (하드코딩)
    private var localizedTexts: OnboardingTexts {
        systemLanguage == "ko" ? .korean : .english
    }
    
    var body: some View {
        ZStack {
            Color.modernBackground
                .ignoresSafeArea()
                .onTapGesture {
                    isNameFieldFocused = false
                }
            
            ScrollView {
                VStack(spacing: 40) {
                    logoSection
                        .onTapGesture {
                            isNameFieldFocused = false
                        }
                    
                    formSection
                    
                    continueButton
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
        .onAppear {
            initializeDefaults()
        }
        .alert(localizedTexts.errorTitle, isPresented: $showError) {
            Button(localizedTexts.okButton, role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
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
        // ⭐ 시스템 언어 우선
        if systemLanguage == "ko" {
            return .korean
        }
        return Language(rawValue: profileLanguage) ?? .english
    }
    
    // MARK: - UI Components
    
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
    
    private var continueButton: some View {
        Button(action: {
            isNameFieldFocused = false
            Task {
                await completeOnboarding()
            }
        }) {
            Group {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(localizedTexts.getStartedButton)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundColor(.white)
            .background(isValid ? Color(hex: "00C896") : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!isValid || isSubmitting)
        .padding(.top, 8)
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
                let appLanguage: AppLanguage = (selectedLanguage == .korean) ? .korean : .english
                localizationManager.setLanguage(appLanguage)
            }
            print("✅ Language synchronized")
            
            await MainActor.run {
                authService.isNewUser = false
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
    let getStartedButton: String
    let nameEmptyError: String
    let nameTooLongError: String
    let errorTitle: String
    let okButton: String
    
    static let english = OnboardingTexts(
        title: "Let's set up your profile",
        displayNameLabel: "Display Name",
        namePlaceholder: "Enter your name",
        languageLabel: "Language",
        getStartedButton: "Get Started",
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
        getStartedButton: "시작하기",
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
