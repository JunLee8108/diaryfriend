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
    
    // Sign Out 관련 State
    @State private var showSignOutConfirmation = false
    @State private var signOutError: String?
    @State private var showSignOutError = false
    
    // Character 관련 State
    @State private var selectedCharacter: CharacterWithAffinity?
    @State private var isExpanded = false
    
    // 처음 표시할 캐릭터 수
    private let initialDisplayCount = 6
    
    // 표시할 캐릭터 목록
    private var displayedCharacters: [CharacterWithAffinity] {
        if isExpanded {
            return characterStore.allCharacters
        } else {
            return Array(characterStore.allCharacters.prefix(initialDisplayCount))
        }
    }
    
    // 더보기 버튼 표시 여부
    private var shouldShowExpandButton: Bool {
        characterStore.allCharacters.count > initialDisplayCount
    }
    
    // 남은 캐릭터 수
    private var remainingCount: Int {
        max(0, characterStore.allCharacters.count - initialDisplayCount)
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
            .padding(.top, 40)
//            .navigationTitle("Profile")
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
                title: "Sign Out",
                message: "Are you sure you want to sign out?",
                icon: "rectangle.portrait.and.arrow.right",
                confirmText: "Sign Out",
                cancelText: "Cancel",
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
            .alert("Sign Out Failed", isPresented: $showSignOutError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(signOutError ?? "Failed to sign out. Please try again.")
            }
        }
        .onAppear {
            print("🔍 ProfileView - Current user: \(authService.currentUserId?.uuidString.prefix(8) ?? "none")")
            print("🔍 Characters count: \(characterStore.allCharacters.count)")
            if let first = characterStore.allCharacters.first {
                print("🔍 First character following: \(first.isFollowing)")
                print("🔍 User_Character: \(first.User_Character?.first?.is_following ?? false)")
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
                Text(UserProfileStore.shared.currentDisplayName)
                    .font(.headline)
                
                Text(authService.currentUser?.email ?? "User")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sign Out Button - Icon Only (ProgressView 제거)
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
                Label("Settings", systemImage: "gearshape")
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
    
    // MARK: - Characters Section
    private var charactersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("AI Characters")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                
                Spacer()
                
                Text("\(characterStore.followingCharacters.count) following")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Content
            if characterStore.isLoading && characterStore.allCharacters.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if characterStore.allCharacters.isEmpty {
                Text("No characters available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
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
                    .animation(.easeInOut(duration: 0.3), value: isExpanded)
                    
                    // Show More/Less Button
                    if shouldShowExpandButton {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Spacer()
                                
                                if isExpanded {
                                    Label("Show Less", systemImage: "chevron.up")
                                        .font(.system(size: 14, weight: .medium))
                                } else {
                                    HStack(spacing: 4) {
                                        Text("Show \(remainingCount) More")
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
}

// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(AuthService())
}
