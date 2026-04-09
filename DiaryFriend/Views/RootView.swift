//
//  RootView.swift
//  DiaryFriend
//

import SwiftUI

struct RootView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var userProfileStore = UserProfileStore.shared
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var statsDataStore = StatsDataStore.shared
    @StateObject private var characterStore = CharacterStore.shared
    
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var isInitialized = false
    @State private var currentUserId: UUID?
    
    @State private var showLaunchScreen = true
    @State private var showSessionExpiredModal = false
    @State private var expiredUserId: UUID?
    
    @Localized(.session_expired_title) var sessionExpiredTitle
    @Localized(.session_expired_message) var sessionExpiredMessage
    @Localized(.common_ok) var okButton
    
    var body: some View {
        ZStack {
            Group {
                if authService.isAuthenticated {
                    // ✅ 신규 유저 체크 추가
                    if authService.isNewUser {
                        OnboardingView()
                            .environmentObject(authService)
                            .environmentObject(userProfileStore)
                            .environmentObject(localizationManager)
                            .transition(.opacity)
                    } else {
                        MainView()
                            .environmentObject(authService)
                            .environmentObject(userProfileStore)
                            .environmentObject(dataStore)
                            .environmentObject(statsDataStore)
                            .environmentObject(characterStore)
                            .transition(.opacity)
                    }
                } else {
                    LoginView()
                        .environmentObject(authService)
                        .transition(.opacity)
                }
            }
            
            if showLaunchScreen {
                CustomLaunchView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onOpenURL { url in
            print("🔗 App opened with URL: \(url)")
            
            if url.scheme == "diaryfriend" && url.host == "auth-callback" {
                Task {
                    do {
                        try await authService.handleDeepLink(url)
                    } catch {
                        print("❌ Failed to handle deep link: \(error)")
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification
        )) { _ in
            Task {
                await validateSession()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
        .animation(.easeInOut, value: authService.isNewUser)  // ✅ isNewUser 변화도 애니메이션
        .task {
            guard !isInitialized else { return }
            
            await initializeApp()
            
            withAnimation(.easeOut(duration: 0.4)) {
                showLaunchScreen = false
            }
        }
        .onChange(of: authService.currentUserId) { oldValue, newValue in
            Task {
                await handleUserChange(from: oldValue, to: newValue)
            }
        }
        .infoModal(
            isPresented: $showSessionExpiredModal,
            title: sessionExpiredTitle,
            message: sessionExpiredMessage,
            icon: "exclamationmark.triangle",
            iconColor: Color(hex: "FF9800"),
            buttonText: okButton,
            onDismiss: {
                Task {
                    await handleSessionExpiration()
                }
            }
        )
    }
    
    // MARK: - Initialization
    
    private func initializeApp() async {
        Logger.debug("🚀 App initialization started")
        
        await authService.initialize()
        
        if let userId = authService.currentUserId {
            await setupUserData(userId)
            currentUserId = userId
            
            await localizationManager.syncWithUserProfile()
        }
        
        isInitialized = true
        print("✅ RootView: App initialization complete")
    }
    
    // MARK: - Session Validation
    
    private func validateSession() async {
        guard authService.isAuthenticated,
              let userId = authService.currentUserId else { return }
        
        do {
            try await authService.refreshSession()
            print("✅ Session valid")
        } catch {
            print("⚠️ Session invalid: \(error)")
            
            await MainActor.run {
                expiredUserId = userId
                showSessionExpiredModal = true
            }
        }
    }
    
    private func handleSessionExpiration() async {
        guard let userId = expiredUserId else {
            print("⚠️ No expired userId found")
            return
        }
        
        print("🗑️ Handling session expiration for user: \(userId.uuidString.prefix(8))")
        
        do {
            try RealmConfiguration.shared.deleteUserRealmFile(userId.uuidString)
            print("✅ Realm file deleted due to session expiration")
        } catch {
            print("⚠️ Failed to delete Realm file: \(error)")
        }
        
        try? await authService.signOut()
        
        await MainActor.run {
            expiredUserId = nil
        }
    }
    
    // MARK: - User Change Handling
    
    private func handleUserChange(from oldUserId: UUID?, to newUserId: UUID?) async {
        guard isInitialized, oldUserId != newUserId else { return }
        
        print("🔄 RootView: User change detected")
        print("  From: \(oldUserId?.uuidString.prefix(8) ?? "none")")
        print("  To: \(newUserId?.uuidString.prefix(8) ?? "none")")
        
        if oldUserId != nil {
            await clearUserData()
        }
        
        if let userId = newUserId {
            await setupUserData(userId)
            await localizationManager.syncWithUserProfile()
        }
        
        currentUserId = newUserId
    }
    
    // MARK: - User Data Management
    
    private func setupUserData(_ userId: UUID) async {
        await RealmManager.shared.setupRealm(for: userId.uuidString)
        
        // ✅ 신규 유저도 Character는 로드
        if !authService.isNewUser {
            // 기존 유저: 모든 데이터 로드
            async let dataLoad: () = dataStore.initialLoad()
            async let characterLoad: () = characterStore.loadAllCharacters()
            _ = await (dataLoad, characterLoad)
            
            prefetchAvatars()
            
            print("✅ RootView: User data setup complete")
            print("  - Posts: \(dataStore.posts.count)")
            print("  - Characters: \(characterStore.allCharacters.count)")
        } else {
            // ✅ 신규 유저: Character만 로드 (Post는 아직 없음)
            await characterStore.loadAllCharacters()
            
            print("ℹ️ RootView: New user - loaded characters only")
            print("  - Characters: \(characterStore.allCharacters.count)")
        }
    }
    
    private func clearUserData() async {
        print("🧹 RootView: Clearing previous user data...")
        
        await dataStore.clearAllData()
        await characterStore.clearAllData()
        await UserProfileStore.shared.clearProfile()
        
        await MainActor.run {
            statsDataStore.clearAllCache()
            ChatService.shared.clearCache()
        }
        
        await ImageCache.shared.clearCache()
        
        print("✅ RootView: User data cleared")
    }
    
    // MARK: - Helper Methods
    
    private func prefetchAvatars() {
        let avatarURLs = characterStore.allCharacters
            .compactMap { $0.avatar_url }
            .filter { !$0.isEmpty }
            .prefix(5)
        
        if !avatarURLs.isEmpty {
            ImageCache.shared.prefetch(urls: Array(avatarURLs))
            print("📦 Prefetched \(avatarURLs.count) character avatars")
        }
    }
}
