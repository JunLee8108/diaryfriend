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
    @Localized(.settings_reminder) var reminderLabel
    @Localized(.settings_reminder_time) var reminderTimeLabel
    @Localized(.error_title) var errorTitle
    @Localized(.common_ok) var okButton

    // Sheet 표시 State
    @State private var showEditName = false
    @State private var showLanguageSelection = false
    @State private var showHelp = false
    @State private var showDeleteAccount = false

    // ⭐ 언어 변경 로딩 상태
    @State private var isLanguageLoading = false

    // 알림 State
    @State private var isReminderEnabled = NotificationManager.shared.isEnabled
    @State private var reminderTime = NotificationManager.shared.reminderTime
    @State private var isNotificationDenied = false
    @State private var showNotificationDeniedAlert = false

    @Environment(\.scenePhase) private var scenePhase

    @Localized(.notification_denied_banner) var deniedBannerText
    @Localized(.notification_denied_open_settings) var openSettingsText
    @Localized(.notification_denied_alert_title) var deniedAlertTitle
    @Localized(.notification_denied_alert_message) var deniedAlertMessage
    
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

                Toggle(isOn: $isReminderEnabled) {
                    Label(reminderLabel, systemImage: "bell")
                }
                .tint(Color(hex: "00C896"))
                .disabled(isNotificationDenied)
                .onChange(of: isReminderEnabled) { _, newValue in
                    if newValue {
                        scheduleReminder()
                    } else {
                        NotificationManager.shared.cancelAll()
                    }
                }

                if isReminderEnabled {
                    DatePicker(
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    ) {
                        Label(reminderTimeLabel, systemImage: "clock")
                    }
                    .onChange(of: reminderTime) { _, newValue in
                        scheduleReminder()
                    }
                }

                if isNotificationDenied {
                    Button {
                        Task {
                            let status = await NotificationManager.shared.authorizationStatus()
                            if status == .notDetermined {
                                let granted = await NotificationManager.shared.requestPermission()
                                await MainActor.run {
                                    if granted {
                                        isNotificationDenied = false
                                        isReminderEnabled = true
                                        scheduleReminder()
                                    }
                                }
                            } else {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    await UIApplication.shared.open(url)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 13))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(deniedBannerText)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Text(openSettingsText)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(hex: "00C896"))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                #if DEBUG
                Button("🔔 Send Test Notification (5s)") {
                    Task {
                        let granted = await NotificationManager.shared.requestPermission()
                        if granted {
                            NotificationManager.shared.sendTestNotification()
                        }
                    }
                }
                .foregroundColor(Color(hex: "00C896"))
                #endif
            }
            
            // About Section
            Section(aboutSection) {
                HStack {
                    Text(versionLabel)
                    Spacer()
                    Text("1.2.1")
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
        .onAppear { checkSystemNotificationStatus() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkSystemNotificationStatus()
            }
        }
        // ⭐ 언어 변경 로딩 overlay (전체 화면)
        .overlay {
            if isLanguageLoading {
                ZStack {
                    Color.clear
                        .background(.ultraThinMaterial)  // 반투명 블러
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
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
                isLoadingBinding: $isLanguageLoading,  // ⭐ binding 전달
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
    
    // MARK: - Notification Helpers

    private func checkSystemNotificationStatus() {
        Task {
            let status = await NotificationManager.shared.authorizationStatus()
            await MainActor.run {
                if status == .denied || status == .notDetermined {
                    if NotificationManager.shared.isEnabled {
                        NotificationManager.shared.cancelAll()
                        isReminderEnabled = false
                    }
                    isNotificationDenied = true
                } else {
                    isNotificationDenied = false
                }
            }
        }
    }

    private func scheduleReminder() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        NotificationManager.shared.scheduleDailyReminder(
            hour: components.hour ?? 21,
            minute: components.minute ?? 0
        )
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
