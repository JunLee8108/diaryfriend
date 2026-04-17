//
//  QuickEntryCard.swift
//  DiaryFriend
//
//  Quick Entry: 무드 + 한 줄 일기
//

import SwiftUI

struct QuickEntryCard: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedMood: Mood = .neutral
    @State private var text: String = ""
    @State private var isSaving = false
    @FocusState private var isFocused: Bool

    @Localized(.quick_entry_prompt) var promptText
    @Localized(.quick_entry_placeholder) var placeholderText
    @Localized(.mood_happy) var happyText
    @Localized(.mood_neutral) var neutralText
    @Localized(.mood_sad) var sadText

    private var hasTodayEntry: Bool {
        let today = DateUtility.shared.dateString(from: Date())
        return !dataStore.posts(for: today).isEmpty
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
            VStack(spacing: 18) {
                Text(promptText)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.top, 4)

                // 무드 패드 3열
                HStack(spacing: 12) {
                    ForEach(Mood.allCases) { mood in
                        MoodPadButton(
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
                .padding(.horizontal, 8)

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
            .padding(.vertical, 18)
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
                    allowAIComments: true
                )
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                isSaving = false
            }
        }
    }
}

// MARK: - Mood Pad Button (ConsolePad 스타일)
private struct MoodPadButton: View {
    let mood: Mood
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var baseColor: Color {
        colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "D8D8D8")
    }

    private var surfaceTop: Color {
        if isSelected {
            return colorScheme == .dark ? mood.accentColor.opacity(0.25) : mood.backgroundColor
        }
        return colorScheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "F0F0F0")
    }

    private var surfaceBottom: Color {
        if isSelected {
            return colorScheme == .dark ? mood.accentColor.opacity(0.15) : mood.backgroundColor.opacity(0.7)
        }
        return colorScheme == .dark ? Color(hex: "222222") : Color(hex: "E4E4E4")
    }

    private var edgeColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.6) : Color.black.opacity(0.12)
    }

    private var highlightColor: Color {
        if isSelected {
            return mood.accentColor.opacity(colorScheme == .dark ? 0.2 : 0.3)
        }
        return colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.9)
    }

    var body: some View {
        Button(action: onTap) {
            GeometryReader { geometry in
                let size = geometry.size.width

                ZStack {
                    // Layer 1: 베이스 받침
                    RoundedRectangle(cornerRadius: 16)
                        .fill(baseColor)

                    // Layer 2: 하단 엣지
                    RoundedRectangle(cornerRadius: 14)
                        .fill(edgeColor)
                        .padding(2)

                    // Layer 3: 상단면 그라디언트
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [surfaceTop, surfaceBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.horizontal, 2)
                        .padding(.top, 2)
                        .padding(.bottom, 4)

                    // Layer 4: 하이라이트 스트로크
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(highlightColor, lineWidth: 1)
                        .padding(.horizontal, 3)
                        .padding(.top, 3)
                        .padding(.bottom, 5)

                    // Layer 5: 콘텐츠
                    VStack(spacing: 6) {
                        Image(systemName: isSelected ? mood.filledIcon : mood.weatherIcon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(isSelected ? mood.accentColor : .secondary)

                        Text(label)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(isSelected ? mood.accentColor : .secondary)
                    }
                }
                .frame(width: size, height: size)
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.4 : 0.08),
                    radius: 6, x: 0, y: 3
                )
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(MoodPadPressStyle())
    }
}

// MARK: - Press Animation
private struct MoodPadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
