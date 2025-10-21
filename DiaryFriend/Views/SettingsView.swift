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
            Section("Profile") {
                // Display Name Row
                HStack {
                    Label("Name", systemImage: "person.text.rectangle")
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
                    Label("Language", systemImage: "globe")
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
            Section("Settings") {
                HStack {
                    Label("Help", systemImage: "questionmark.circle")
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
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Developer")
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
                    Text("Delete Account")
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
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorAlertMessage)
        }
    }
    
    // MARK: - Delete Account Logic
    
    private func deleteAccount() async {
        do {
            try await authService.deleteAccount()
            
        } catch AuthError.networkRequired {
            // 오프라인 에러 처리
            await MainActor.run {
                self.errorAlertMessage = "Internet connection is required to delete your account. Please check your connection and try again."
                self.showErrorAlert = true
            }
            
        } catch AuthError.notAuthenticated {
            await MainActor.run {
                self.errorAlertMessage = "Authentication error. Please sign in again."
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

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthService())
    }
}
