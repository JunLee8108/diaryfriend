//
//  ChatHistoryView.swift
//  DiaryFriend
//

import SwiftUI

struct ChatHistoryView: View {
    let postId: Int

    @Environment(\.dismiss) private var dismiss
    @StateObject private var characterStore = CharacterStore.shared
    @ObservedObject private var profileStore = UserProfileStore.shared

    @State private var messages: [ChatMessage] = []
    @State private var characterId: Int?
    @State private var characterName: String = ""
    @State private var characterAvatarUrl: String?
    @State private var isLoading = true
    @State private var selectedCharacterForDetail: CharacterWithAffinity?

    @Localized(.post_detail_view_chat) var viewChatTitle

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if messages.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.text.bubble.right")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("No conversation found")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages.filter { $0.sender != .system }) { message in
                                ChatHistoryBubble(
                                    message: message,
                                    characterName: characterName,
                                    characterAvatarUrl: characterAvatarUrl,
                                    onAvatarTap: {
                                        handleAvatarTap()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
            }
            .background(Color.modernBackground)
            .navigationTitle(viewChatTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
        }
        .sheet(item: $selectedCharacterForDetail) { character in
            CharacterDetailSheet(
                character: character,
                onFollowToggle: {
                    await characterStore.toggleFollowing(characterId: character.id)
                    if let updated = characterStore.allCharacters.first(where: { $0.id == character.id }) {
                        selectedCharacterForDetail = updated
                    }
                }
            )
        }
        .task {
            await loadChatHistory()
        }
    }

    private func loadChatHistory() async {
        let result = await ChatService.shared.fetchChatHistory(postId: postId)
        messages = result.messages

        if let charId = result.characterId,
           let character = await characterStore.getCharacter(id: charId) {
            characterId = charId
            characterName = character.localizedName(isKorean: profileStore.isKoreanUser)
            characterAvatarUrl = character.avatar_url
        }

        isLoading = false
    }

    private func handleAvatarTap() {
        guard let charId = characterId,
              let character = characterStore.allCharacters.first(where: { $0.id == charId }) else {
            return
        }
        selectedCharacterForDetail = character
    }
}

// MARK: - Chat History Bubble (Read-only)
struct ChatHistoryBubble: View {
    let message: ChatMessage
    let characterName: String
    let characterAvatarUrl: String?
    let onAvatarTap: (() -> Void)?

    private var isUser: Bool {
        message.sender == .user
    }

    private var avatarInitial: String {
        String(characterName.first ?? "?").uppercased()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isUser {
                Spacer(minLength: 60)
            } else {
                Button(action: { onAvatarTap?() }) {
                    CachedAvatarImage(
                        url: characterAvatarUrl,
                        size: 32,
                        initial: avatarInitial
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(onAvatarTap == nil)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if !isUser {
                    Text(characterName)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }

                Text(message.content)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(isUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isUser ? Color(hex: "00A077") : Color.modernSurfacePrimary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isUser ? Color.clear : Color.gray.opacity(0.1), lineWidth: 1)
                    )
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}
