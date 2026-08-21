//
//  SettingsView.swift
//  DiaryFriend
//
//  통합 설정 화면 - Profile Settings + Delete Account 추가
//  (시스템 List 대신 modernCard 섹션으로 홈/프로필과 시각 언어 통일)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Profile Settings Section
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(profileSection)

                    sectionCard {
                        navigationRow(
                            label: nameLabel,
                            icon: "person.text.rectangle",
                            value: profileStore.currentDisplayName
                        ) {
                            showEditName = true
                        }

                        rowDivider

                        navigationRow(
                            label: languageLabel,
                            icon: "globe",
                            value: profileStore.currentLanguage?.displayName ?? "English"
                        ) {
                            showLanguageSelection = true
                        }
                    }
                }

                // Settings Section
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(settingsTitle)

                    sectionCard {
                        navigationRow(label: helpLabel, icon: "questionmark.circle") {
                            showHelp = true
                        }

                        rowDivider

                        // 리마인더 토글
                        HStack {
                            Label(reminderLabel, systemImage: "bell")
                                .font(.system(size: 15))
                                .foregroundColor(.primary)

                            Spacer()

                            Toggle("", isOn: $isReminderEnabled)
                                .labelsHidden()
                                .tint(Color(hex: "00C896"))
                                .disabled(isNotificationDenied)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .onChange(of: isReminderEnabled) { _, newValue in
                            if newValue {
                                scheduleReminder()
                            } else {
                                NotificationManager.shared.cancelAll()
                            }
                        }

                        if isReminderEnabled {
                            rowDivider

                            DatePicker(
                                selection: $reminderTime,
                                displayedComponents: .hourAndMinute
                            ) {
                                Label(reminderTimeLabel, systemImage: "clock")
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .onChange(of: reminderTime) { _, newValue in
                                scheduleReminder()
                            }
                        }

                        if isNotificationDenied {
                            rowDivider

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
                                            .multilineTextAlignment(.leading)
                                        Text(openSettingsText)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color(hex: "00C896"))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.pressable)
                        }

                        #if DEBUG
                        rowDivider

                        Button("🔔 Send Test Notification (5s)") {
                            Task {
                                let granted = await NotificationManager.shared.requestPermission()
                                if granted {
                                    NotificationManager.shared.sendTestNotification()
                                }
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "00C896"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        #endif
                    }
                }

                // About Section
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(aboutSection)

                    sectionCard {
                        infoRow(label: versionLabel, value: "1.2.1")
                        rowDivider
                        infoRow(label: developerLabel, value: "Jun Lee")
                    }
                }

                // Delete Account Section
                sectionCard {
                    Button(action: {
                        showDeleteAccount = true
                    }) {
                        Text(deleteAccountLabel)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .background(Color.modernBackground)
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

    // MARK: - Section Building Blocks

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
            .tracking(0.5)
            .padding(.horizontal, 4)
    }

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.vertical, 4)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .modernCard()
    }

    private var rowDivider: some View {
        Divider()
            .padding(.leading, 52)
            .padding(.trailing, 16)
    }

    /// 탭하면 이동/시트가 열리는 행 (chevron + 선택적 현재값)
    private func navigationRow(
        label: String,
        icon: String,
        value: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)

                Spacer()

                if let value {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    /// 정적 정보 행 (버전/개발자)
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
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
