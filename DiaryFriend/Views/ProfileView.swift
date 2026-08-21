//
//  ProfileView.swift
//  DiaryFriend
//
//  캐릭터 관리 중심 프로필 화면
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var characterStore = CharacterStore.shared
    @ObservedObject private var profileStore = UserProfileStore.shared
    
    // ⭐ 다국어 적용
    @Localized(.settings_title) var settingsTitle
    @Localized(.profile_sign_out_title) var signOutTitle
    @Localized(.profile_sign_out_message) var signOutMessage
    @Localized(.profile_sign_out_confirm) var signOutConfirm
    @Localized(.common_cancel) var cancelText
    @Localized(.profile_sign_out_failed) var signOutFailedTitle
    @Localized(.profile_sign_out_error) var signOutErrorMessage
    @Localized(.common_ok) var okText
    @Localized(.profile_ai_characters) var aiCharactersTitle
    @Localized(.profile_following) var followingText
    @Localized(.profile_no_characters) var noCharactersText
    @Localized(.profile_show_less) var showLessText
    @Localized(.profile_search_placeholder) var searchPlaceholderText
    @Localized(.profile_search_no_results) var searchNoResultsText

    // Sign Out 관련 State
    @State private var showSignOutConfirmation = false
    @State private var signOutError: String?
    @State private var showSignOutError = false

    // Character 관련 State
    @State private var selectedCharacter: CharacterWithAffinity?
    @State private var isExpanded = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    // 처음 표시할 캐릭터 수
    private let initialDisplayCount = 6

    /// 통합 캐릭터 목록 (modern 먼저, classic 뒤 — 기존 섹션 순서 유지)
    private var combinedCharacters: [CharacterWithAffinity] {
        characterStore.modernCharacters + characterStore.classicCharacters
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private var isSearching: Bool { !trimmedSearch.isEmpty }

    /// 검색 필터 — 영문 name과 한국어 korean_name 모두 부분 일치
    private var filteredCharacters: [CharacterWithAffinity] {
        guard isSearching else { return combinedCharacters }
        return combinedCharacters.filter { character in
            character.name.localizedCaseInsensitiveContains(trimmedSearch)
                || (character.korean_name?.localizedCaseInsensitiveContains(trimmedSearch) ?? false)
        }
    }

    /// 실제 표시 목록 — 검색 중이면 매칭 전체, 아니면 접힘 상태에 따라 6개 제한
    private var displayedCharacters: [CharacterWithAffinity] {
        if isSearching || isExpanded {
            return filteredCharacters
        }
        return Array(filteredCharacters.prefix(initialDisplayCount))
    }

    private var shouldShowExpandButton: Bool {
        !isSearching && combinedCharacters.count > initialDisplayCount
    }

    private var remainingCount: Int {
        max(0, combinedCharacters.count - initialDisplayCount)
    }

    // ⭐ "Show X More" 동적 텍스트
    private var showMoreText: String {
        String(format: LocalizationManager.shared.localized(.profile_show_more), remainingCount)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // User Info Section with Sign Out
                    userInfoSection
                    
                    // Settings Button
                    settingsButton
                    
                    // AI Characters Section
                    charactersSection
                }
                .padding(.horizontal)
            }
            .padding(.top, 16)
            .safeAreaInset(edge: .bottom) {
                // TabBar 높이를 고려한 안전 영역 확보
                Color.clear.frame(height: 20)
            }
            .background(Color.modernBackground)
            .sheet(item: $selectedCharacter) { character in
                CharacterDetailSheet(
                    character: character,
                    onFollowToggle: {
                        await characterStore.toggleFollowing(characterId: character.id)
                        // 선택된 캐릭터 업데이트
                        if let updated = characterStore.allCharacters.first(where: { $0.id == character.id }) {
                            selectedCharacter = updated
                        }
                    }
                )
            }
            // ConfirmationModal로 교체
            .confirmationModal(
                isPresented: $showSignOutConfirmation,
                title: signOutTitle,
                message: signOutMessage,
                icon: "rectangle.portrait.and.arrow.right",
                confirmText: signOutConfirm,
                cancelText: cancelText,
                isDestructive: true,
                onConfirm: {
                    do {
                        try await authService.signOut()
                    } catch {
                        signOutError = error.localizedDescription
                        showSignOutError = true
                    }
                }
            )
            // Sign Out 실패 시 에러 알림
            .alert(signOutFailedTitle, isPresented: $showSignOutError) {
                Button(okText, role: .cancel) { }
            } message: {
                Text(signOutError ?? signOutErrorMessage)
            }
        }
        .onAppear {
            print("📍 ProfileView - Current user: \(authService.currentUserId?.uuidString.prefix(8) ?? "none")")
            print("📍 Characters count: \(characterStore.allCharacters.count)")
            if let first = characterStore.allCharacters.first {
                print("📍 First character following: \(first.isFollowing)")
                print("📍 User_Character: \(first.User_Character?.first?.is_following ?? false)")
            }
        }
    }
    
    // MARK: - User Info Section with Sign Out
    private var userInfoSection: some View {
        HStack(spacing: 15) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.modernSurfaceTertiary)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(profileStore.currentDisplayName)
                    .font(.headline)
                
                Text(authService.currentUser?.email ?? "User")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sign Out Button - Icon Only
            Button(action: {
                showSignOutConfirmation = true
            }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                    .frame(width: 32, height: 32)
            }
        }
        .padding()
        .background(Color.modernSurfacePrimary)
        .cornerRadius(12)
    }
    
    // MARK: - Settings Button
    private var settingsButton: some View {
        NavigationLink(destination: SettingsView()) {
            HStack {
                Label(settingsTitle, systemImage: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.modernSurfacePrimary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Characters Section (통합: modern + classic 단일 리스트 + 검색)
    private var charactersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(aiCharactersTitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))

                Spacer()

                Text("\(characterStore.followingCharacters.count) \(followingText)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            characterSearchField

            if characterStore.isLoading && characterStore.allCharacters.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if combinedCharacters.isEmpty {
                Text(noCharactersText)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if displayedCharacters.isEmpty {
                // 검색 결과 없음
                Text(searchNoResultsText)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color.modernSurfacePrimary)
                    .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(displayedCharacters.enumerated()), id: \.element.id) { index, character in
                            VStack(spacing: 0) {
                                CharacterCard(
                                    character: character,
                                    onFollowToggle: {
                                        await characterStore.toggleFollowing(characterId: character.id)
                                    },
                                    index: index
                                )
                                .onTapGesture {
                                    selectedCharacter = character
                                }

                                if character.id != displayedCharacters.last?.id {
                                    Divider()
                                        .padding(.leading, 62)
                                }
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: displayedCharacters.count)

                    if shouldShowExpandButton {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Spacer()

                                if isExpanded {
                                    Label(showLessText, systemImage: "chevron.up")
                                        .font(.system(size: 14, weight: .medium))
                                } else {
                                    HStack(spacing: 4) {
                                        Text(showMoreText)
                                        Image(systemName: "chevron.down")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                }

                                Spacer()
                            }
                            .foregroundColor(Color(hex: "00A077"))
                            .padding(.vertical, 16)
                        }
                        .background(
                            Rectangle()
                                .fill(Color.modernSurfaceSecondary)
                        )
                        .padding(.top, 8)
                    }
                }
                .background(Color.modernSurfacePrimary)
                .cornerRadius(12)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Character Search Field
    private var characterSearchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            TextField(searchPlaceholderText, text: $searchText)
                .font(.system(size: 14, design: .rounded))
                .focused($isSearchFocused)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        // 포커스 링: Quick Entry 입력창과 동일한 패턴
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    Color(hex: "00C896").opacity(isSearchFocused ? 0.35 : 0),
                    lineWidth: 1
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchFocused)
        .animation(.easeInOut(duration: 0.15), value: searchText.isEmpty)
    }
}
