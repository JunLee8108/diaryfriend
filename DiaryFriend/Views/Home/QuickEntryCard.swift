//
//  QuickEntryCard.swift
//  DiaryFriend
//
//  Quick Entry: 무드 + 한 줄 일기
//

import SwiftUI

struct QuickEntryCard: View {
    @EnvironmentObject var dataStore: DataStore
    let hasTodayEntry: Bool
    @State private var selectedMood: Mood = .happy
    @State private var text: String = ""
    @State private var isSaving = false
    @FocusState private var isFocused: Bool

    @Localized(.quick_entry_prompt) var promptText
    @Localized(.quick_entry_placeholder) var placeholderText
    @Localized(.mood_happy) var happyText
    @Localized(.mood_neutral) var neutralText
    @Localized(.mood_sad) var sadText

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

                    if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button(action: saveIfValid) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Color(hex: "00C896"))
                        }
                        .disabled(isSaving)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .onTapGesture { isFocused = true }
                .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.modernSurfacePrimary)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func saveIfValid() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isSaving else { return }
        isSaving = true
        isFocused = false

        Task {
            do {
                _ = try await dataStore.createPost(
                    content: trimmed,
                    mood: selectedMood.rawValue,
                    entryDate: Date(),
                    allowAIComments: !CharacterStore.shared.followingCharacters.isEmpty
                )
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                await MainActor.run {
                    text = ""
                    isSaving = false
                    selectedMood = .happy
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
