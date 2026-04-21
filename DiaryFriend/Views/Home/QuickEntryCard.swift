//
//  QuickEntryCard.swift
//  DiaryFriend
//
//  Quick Entry: 무드 + 한 줄 일기
//

import SwiftUI
import UIKit

struct QuickEntryCard: View {
    @EnvironmentObject var dataStore: DataStore
    @StateObject private var characterStore = CharacterStore.shared
    @StateObject private var speechService = SpeechRecognitionService()
    let hasTodayEntry: Bool
    @State private var selectedMood: Mood = .happy
    @State private var text: String = ""
    @State private var isSaving = false
    @State private var isAICommentEnabled: Bool = false
    @State private var showCharacterSelection: Bool = false
    @State private var showMicPermissionAlert: Bool = false
    @State private var micPulse: Bool = false
    @FocusState private var isFocused: Bool

    @Localized(.quick_entry_prompt) var promptText
    @Localized(.quick_entry_placeholder) var placeholderText
    @Localized(.quick_entry_ai_toggle_label) var aiToggleLabel
    @Localized(.quick_entry_no_following_label) var noFollowingLabel
    @Localized(.quick_entry_follow_action) var followActionLabel
    @Localized(.quick_entry_mic_listening) var micListeningText
    @Localized(.quick_entry_mic_permission_title) var micPermissionTitle
    @Localized(.quick_entry_mic_permission_message) var micPermissionMessage
    @Localized(.quick_entry_mic_permission_settings) var micPermissionSettings
    @Localized(.common_cancel) var cancelText
    @Localized(.mood_happy) var happyText
    @Localized(.mood_neutral) var neutralText
    @Localized(.mood_sad) var sadText

    private var hasFollowingCharacters: Bool {
        !characterStore.followingCharacters.isEmpty
    }

    private func moodLabel(for mood: Mood) -> String {
        switch mood {
        case .happy: return happyText
        case .neutral: return neutralText
        case .sad: return sadText
        }
    }

    var body: some View {
        if !hasTodayEntry {
            VStack(spacing: 14) {
                Text(promptText)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                // 무드 칩 (pill 스타일)
                HStack(spacing: 10) {
                    ForEach(Mood.allCases) { mood in
                        MoodChip(
                            mood: mood,
                            label: moodLabel(for: mood),
                            isSelected: selectedMood == mood,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedMood = mood
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        )
                    }
                }

                // 텍스트 입력 + 마이크 + 전송
                HStack(spacing: 10) {
                    TextField(
                        speechService.isRecording ? micListeningText : placeholderText,
                        text: $text
                    )
                        .font(.system(size: 14, design: .rounded))
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit { saveIfValid() }
                        .disabled(speechService.isRecording)

                    // Mic 버튼
                    Button(action: handleMicTap) {
                        Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(
                                speechService.isRecording
                                    ? Color(hex: "FF6B6B")
                                    : .secondary
                            )
                            .scaleEffect(speechService.isRecording && micPulse ? 1.18 : 1.0)
                    }
                    .disabled(isSaving)

                    // Send 버튼
                    Button(action: saveIfValid) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "00C896"))
                    }
                    .disabled(
                        isSaving
                        || speechService.isRecording
                        || text.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                    .opacity(text.trimmingCharacters(in: .whitespaces).isEmpty ? 0 : 1)
                    .allowsHitTesting(
                        !speechService.isRecording
                        && !text.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                }
                .frame(height: 24)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture {
                    if !speechService.isRecording {
                        isFocused = true
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
                .animation(.easeInOut(duration: 0.2), value: speechService.isRecording)

                // AI 댓글 허용 토글 (compact inline)
                aiToggleRow
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.modernSurfacePrimary)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            .sheet(isPresented: $showCharacterSelection) {
                CharacterSelectionView(isPresented: $showCharacterSelection)
                    .onDisappear {
                        if hasFollowingCharacters && !isAICommentEnabled {
                            isAICommentEnabled = true
                        }
                    }
            }
            .task {
                if characterStore.allCharacters.isEmpty {
                    await characterStore.loadAllCharacters()
                }
                if hasFollowingCharacters {
                    isAICommentEnabled = true
                }
            }
            .onChange(of: hasFollowingCharacters) { _, newValue in
                if !newValue {
                    isAICommentEnabled = false
                }
            }
            // Speech: transcribed text를 입력 필드에 반영
            .onChange(of: speechService.transcribedText) { _, newValue in
                if speechService.isRecording && !newValue.isEmpty {
                    text = newValue
                }
            }
            // Speech: 녹음 상태 변화 → pulse 애니메이션 + 음성 종료 후 focus
            .onChange(of: speechService.isRecording) { _, recording in
                if recording {
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        micPulse = true
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        micPulse = false
                    }
                }
            }
            // 카드 사라지거나 앱 백그라운드 진입 시 녹음 정지
            .onDisappear {
                speechService.stopRecording()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                speechService.stopRecording()
            }
            .alert(micPermissionTitle, isPresented: $showMicPermissionAlert) {
                Button(micPermissionSettings) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button(cancelText, role: .cancel) {}
            } message: {
                Text(micPermissionMessage)
            }
        }
    }

    // MARK: - Mic Flow

    private func handleMicTap() {
        if speechService.isRecording {
            speechService.stopRecording()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        // 이미 권한 있으면 바로 녹음
        if speechService.isAuthorized {
            startDictation()
            return
        }

        // 권한 요청
        Task {
            let granted = await speechService.requestAuthorization()
            if granted {
                await MainActor.run { startDictation() }
            } else {
                await MainActor.run { showMicPermissionAlert = true }
            }
        }
    }

    private func startDictation() {
        let isKorean = LocalizationManager.shared.currentLanguage == .korean
        let locale = Locale(identifier: isKorean ? "ko_KR" : "en_US")
        do {
            isFocused = false
            try speechService.startRecording(locale: locale)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            print("❌ Speech start failed: \(error.localizedDescription)")
        }
    }

    // MARK: - AI Toggle Row (Compact)
    @ViewBuilder
    private var aiToggleRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundColor(
                    hasFollowingCharacters
                        ? Color(hex: "00C896")
                        : .secondary
                )

            if hasFollowingCharacters {
                Text(aiToggleLabel)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Toggle("", isOn: $isAICommentEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "00C896")))
                    .scaleEffect(0.75)
                    .frame(width: 44, height: 24)
            } else {
                Text(noFollowingLabel)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Spacer(minLength: 4)

                Button(action: {
                    showCharacterSelection = true
                }) {
                    HStack(spacing: 3) {
                        Text(followActionLabel)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "00A077"))
                }
                .buttonStyle(PlainButtonStyle())

                Toggle("", isOn: .constant(false))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .gray))
                    .scaleEffect(0.75)
                    .frame(width: 44, height: 24)
                    .disabled(true)
                    .opacity(0.5)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    private func saveIfValid() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isSaving else { return }
        isSaving = true
        isFocused = false

        let shouldAllowAIComments = isAICommentEnabled && hasFollowingCharacters

        Task {
            do {
                _ = try await dataStore.createPost(
                    content: trimmed,
                    mood: selectedMood.rawValue,
                    entryDate: Date(),
                    allowAIComments: shouldAllowAIComments
                )
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                await MainActor.run {
                    text = ""
                    isSaving = false
                    selectedMood = .happy
                    isAICommentEnabled = hasFollowingCharacters
                }
            } catch {
                isSaving = false
            }
        }
    }
}

// MARK: - Mood Chip (Pill 스타일)
private struct MoodChip: View {
    let mood: Mood
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        if isSelected {
            return colorScheme == .dark
                ? mood.accentColor.opacity(0.2)
                : mood.backgroundColor
        }
        return Color(.systemGray6)
    }

    private var borderColor: Color {
        isSelected ? mood.accentColor.opacity(0.4) : Color.clear
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? mood.filledIcon : mood.weatherIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? mood.accentColor : .secondary)

                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? mood.accentColor : .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
