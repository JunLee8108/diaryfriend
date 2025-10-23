// Views/Post/PostAISelectView.swift
import SwiftUI

struct PostAISelectView: View {
    @StateObject private var characterStore = CharacterStore.shared
    @StateObject private var creationManager = PostCreationManager.shared
    @StateObject private var chatService = ChatService.shared
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss
    
    // States
    @State private var permission: DailyPermission?
    @State private var isLoading = true
    @State private var charactersWithSession: Set<Int> = []
    @State private var showCharacterSelection = false
    
    @Localized(.ai_select_header) var aiSelectHeader
    
    private var selectedDate: Date {
        creationManager.selectedDate ?? Date()
    }
    
    var body: some View {
        ZStack {
            Color.modernBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ReadOnlyDateHeader(date: selectedDate)
                
                Group {
                    if isLoading {
                        LoadingStateView()
                    } else if let permission = permission, !permission.canChat {
                        PermissionDeniedView(
                            permission: permission,
                            selectedDate: selectedDate
                        )
                    } else if characterStore.followingCharacters.isEmpty {
                        EmptyStateView(showCharacterSelection: $showCharacterSelection)
                    } else {
                        CharacterListView(
                            characters: characterStore.followingCharacters,
                            charactersWithSession: charactersWithSession,
                            showWarning: permission?.deletedCount == 1,
                            onSelect: handleCharacterSelection
                        )
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(aiSelectHeader)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
        }
        .sheet(isPresented: $showCharacterSelection) {
            CharacterSelectionView(isPresented: $showCharacterSelection)
        }
        .task {
            if creationManager.selectedDate == nil {
                print("Warning: No date selected in PostCreationManager, using today")
                creationManager.selectedDate = Date()
            }
            await checkPermission()
        }
    }
    
    // ✅ handleCharacterSelection 수정
    private func handleCharacterSelection(_ character: CharacterWithAffinity) {
        creationManager.selectedCharacterId = character.id
        creationManager.selectedDate = selectedDate
        navigationCoordinator.push(.aiConversation(characterId: character.id))
    }
    
    // MARK: - Methods
    
    private func checkPermission() async {
        isLoading = true
        
        guard creationManager.selectedDate != nil else {
            print("Warning: No date selected in PostCreationManager")
            creationManager.selectedDate = Date()
            isLoading = false
            return
        }
        
        do {
            let checkedPermission = try await chatService.checkDailyPermission(date: selectedDate)
            permission = checkedPermission
            
            // 🎯 NEW: 단일 쿼리로 세션 확인
            if checkedPermission.canChat && !characterStore.followingCharacters.isEmpty {
                let characterIds = characterStore.followingCharacters.map { $0.id }
                charactersWithSession = try await chatService.getCharactersWithSessions(
                    date: selectedDate,
                    characterIds: characterIds
                )
            }
            
        } catch {
            print("Error checking permission: \(error)")
            permission = DailyPermission(
                canChat: true,
                reason: nil,
                postCount: 0,
                deletedCount: 0
            )
        }
        
        isLoading = false
    }
}

// MARK: - Read-only Date Header

private struct ReadOnlyDateHeader: View {
    let date: Date
    
    private var dateString: String {
        return DateUtility.shared.fullDate(from: date)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Date display만 유지
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(dateString)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.modernSurfacePrimary.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Loading State View

private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.secondary)
            
            Text("Checking permissions...")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Permission Denied View

private struct PermissionDeniedView: View {
    let permission: DailyPermission
    let selectedDate: Date
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: selectedDate)
    }
    
    private var remainingAttempts: Int {
        2 - permission.deletedCount
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Main Message
            VStack(spacing: 8) {
                Text(dateString)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(permission.reason ?? "Diary already written")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Deletion Count Info
            if permission.deletedCount > 0 && permission.deletedCount < 2 {
                VStack(spacing: 12) {
                    Divider()
                        .frame(width: 60)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        
                        Text("Rewrite attempts remaining: \(remainingAttempts)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
            
            // All Attempts Used
            if permission.deletedCount >= 2 {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                    
                    Text("All rewrite attempts used")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundColor(Color(hex: "FF6B6B"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "FF6B6B").opacity(0.1))
                )
            }
            
            // 날짜 변경 안내
            VStack(spacing: 16) {
                Divider()
                    .frame(width: 100)
                    .padding(.top, 20)
                
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                    
                    Text("To select a different date, please go back to the calendar")
                        .font(.system(size: 12, design: .rounded))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            }
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Character List View

private struct CharacterListView: View {
    let characters: [CharacterWithAffinity]
    let charactersWithSession: Set<Int>
    let showWarning: Bool  // 🎯 NEW
    let onSelect: (CharacterWithAffinity) -> Void
    
    @Localized(.ai_select_title) var aiSelectTitle
    @Localized(.ai_select_last_chance) var aiSelectLastChance
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {  // spacing 조정: 24 → 16
                // Title
                Text(aiSelectTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.top, 8)
                
                // 🎯 NEW: Warning banner
                if showWarning {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "FF6B35"))
                        
                        Text(aiSelectLastChance)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                }
                
                // Character Cards
                VStack(spacing: 12) {
                    ForEach(characters, id: \.id) { character in
                        CharacterBubbleCard(
                            character: character,
                            hasSession: charactersWithSession.contains(character.id),
                            onTap: { onSelect(character) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 40)
            }
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Character Bubble Card

private struct CharacterBubbleCard: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let character: CharacterWithAffinity
    let hasSession: Bool  // 🎯 NEW
    let onTap: () -> Void
    
    @Localized(.ai_select_chatted) var aiSelectChattedText: String
    
    // ✅ 언어 체크
    private var isKorean: Bool {
        localizationManager.currentLanguage == .korean
    }
    
    // ✅ 다국어 이름
    private var displayName: String {
        character.localizedName(isKorean: isKorean)
    }
    
    // ✅ 다국어 설명
    private var displayDescription: String? {
        character.localizedDescription(isKorean: isKorean)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Avatar with session indicator
                ZStack(alignment: .topTrailing) {
                    CachedAvatarImage(
                        url: character.avatar_url,
                        size: 50,
                        initial: String(displayName.prefix(1)).uppercased()
                    )
                    
                    // 🎯 NEW: Session badge
                    if hasSession {
                        Circle()
                            .fill(Color(hex: "00C896"))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "message.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 4, y: -4)
                    }
                }
                
                // Character Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // 🎯 NEW: "Chatted" label
                        if hasSession {
                            Text(aiSelectChattedText)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "00C896"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "89dfbc").opacity(0.15))
                                )
                        }
                    }
                    
                    if let description = displayDescription {
                        Text(description)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "C0C0C0"))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.modernSurfacePrimary)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
            )
            // 🎯 NEW: 세션 있는 카드 테두리 강조
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(hasSession ? Color(hex: "89dfbc").opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View

private struct EmptyStateView: View {
    @Binding var showCharacterSelection: Bool  // Binding으로 변경
    
    @Localized(.ai_select_no_friends) var aiSelectNoFriendsText
    @Localized(.ai_select_follow_friends) var aiSelectFollowFriendsText
    @Localized(.ai_select_find_friends) var aiSelectFindFriendsText
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 8) {
                Text(aiSelectNoFriendsText)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(aiSelectFollowFriendsText)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showCharacterSelection = true
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text(aiSelectFindFriendsText)
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(hex: "00C896"))
                )
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}
