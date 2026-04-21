//
//  QuickEntryCard.swift
//  DiaryFriend
//
//  Quick Entry: 무드 + 한 줄 일기
//

import SwiftUI

struct QuickEntryCard: View {
    @EnvironmentObject var dataStore: DataStore
    @StateObject private var characterStore = CharacterStore.shared
    let hasTodayEntry: Bool
    @State private var selectedMood: Mood = .happy
    @State private var text: String = ""
    @State private var isSaving = false
    @State private var isAICommentEnabled: Bool = false
    @State private var showCharacterSelection: Bool = false
    @FocusState private var isFocused: Bool

    @Localized(.quick_entry_prompt) var promptText
    @Localized(.quick_entry_placeholder) var placeholderText
    @Localized(.quick_entry_ai_toggle_label) var aiToggleLabel
    @Localized(.quick_entry_no_following_label) var noFollowingLabel
    @Localized(.quick_entry_follow_action) var followActionLabel
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

                // 텍스트 입력 + 전송
                HStack(spacing: 10) {
                    TextField(placeholderText, text: $text)
                        .font(.system(size: 14, design: .rounded))
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit { saveIfValid() }

                    Button(action: saveIfValid) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color(hex: "00C896"))
                    }
                    .disabled(isSaving || text.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(text.trimmingCharacters(in: .whitespaces).isEmpty ? 0 : 1)
                    .allowsHitTesting(!text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .frame(height: 28)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture { isFocused = true }
                .animation(.easeInOut(duration: 0.2), value: text.isEmpty)

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
