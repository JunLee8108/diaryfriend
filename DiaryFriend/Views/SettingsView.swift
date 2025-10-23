//
//  SettingsView.swift
//  DiaryFriend
//
//  통합 설정 화면 - Profile Settings + Delete Account 추가
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var profileStore = UserProfileStore.shared
    @EnvironmentObject var authService: AuthService
    
    // ⭐ 다국어 적용
    @Localized(.settings_profile) var profileSection
    @Localized(.settings_name) var nameLabel
    @Localized(.settings_language) var languageLabel
    @Localized(.settings_title) var settingsTitle
    @Localized(.settings_help) var helpLabel
    @Localized(.settings_about) var aboutSection
    @Localized(.settings_version) var versionLabel
    @Localized(.settings_developer) var developerLabel
    @Localized(.settings_delete_account) var deleteAccountLabel
    @Localized(.error_title) var errorTitle
    @Localized(.common_ok) var okButton
    
    // Sheet 표시 State
    @State private var showEditName = false
    @State private var showLanguageSelection = false
    @State private var showHelp = false
    @State private var showDeleteAccount = false
    
    // Error State
    @State private var showErrorAlert = false
    @State private var errorAlertMessage = ""
    
    var body: some View {
        List {
            // Profile Settings Section
            Section(profileSection) {
                // Display Name Row
                HStack {
                    Label(nameLabel, systemImage: "person.text.rectangle")
                    Spacer()
                    Text(profileStore.currentDisplayName)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showEditName = true
                }
                
                // Language Row
                HStack {
                    Label(languageLabel, systemImage: "globe")
                    Spacer()
                    Text(profileStore.currentLanguage?.displayName ?? "English")
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showLanguageSelection = true
                }
            }
            
            // Settings Section
            Section(settingsTitle) {
                HStack {
                    Label(helpLabel, systemImage: "questionmark.circle")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showHelp = true
                }
            }
            
            // About Section
            Section(aboutSection) {
                HStack {
                    Text(versionLabel)
                    Spacer()
                    Text("1.1.1")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(developerLabel)
                    Spacer()
                    Text("Jun Lee")
                        .foregroundColor(.secondary)
                }
            }
            
            // Delete Account Section
            Section {
                Button(action: {
                    showDeleteAccount = true
                }) {
                    Text(deleteAccountLabel)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        // Edit Name Sheet
        .sheet(isPresented: $showEditName) {
            EditNameView(
                currentName: profileStore.currentDisplayName,
                onSave: { newName in
                    Task {
                        try await profileStore.updateDisplayName(newName)
                    }
                }
            )
            .presentationDetents([.fraction(0.45)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        // Language Selection Sheet
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView(
                currentLanguage: profileStore.currentLanguage ?? .english,
                onSelect: { language in
                    Task {
                        try await profileStore.updateLanguage(language.rawValue)
                    }
                }
            )
            .presentationDetents([.fraction(0.45)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        // Help Sheet
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        // Delete Account Modal
        .deleteAccountModal(
            isPresented: $showDeleteAccount,
            onConfirm: {
                await deleteAccount()
            },
            onCancel: {
                print("User cancelled account deletion")
            }
        )
        // Error Alert
        .alert(errorTitle, isPresented: $showErrorAlert) {
            Button(okButton, role: .cancel) { }
        } message: {
            Text(errorAlertMessage)
        }
    }
    
    // MARK: - Delete Account Logic
    
    private func deleteAccount() async {
        do {
            try await authService.deleteAccount()
            
        } catch AuthError.networkRequired {
            // ⭐ 다국어 에러 메시지
            await MainActor.run {
                self.errorAlertMessage = LocalizationManager.shared.localized(.error_network_required)
                self.showErrorAlert = true
            }
            
        } catch AuthError.notAuthenticated {
            // ⭐ 다국어 에러 메시지
            await MainActor.run {
                self.errorAlertMessage = LocalizationManager.shared.localized(.error_not_authenticated)
                self.showErrorAlert = true
            }
            
        } catch {
            // 기타 에러
            await MainActor.run {
                self.errorAlertMessage = "Failed to delete account: \(error.localizedDescription)"
                self.showErrorAlert = true
            }
        }
    }
}
