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
            
            withAnimation(.easeOut(duration: 0.2)) {
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

        // Step 1: 세션만 빠르게 확인 (프로필 로드 없음)
        await authService.checkSessionOnly()

        guard let userId = authService.currentUserId else {
            await MainActor.run {
                authService.isLoading = false
            }
            isInitialized = true
            print("✅ RootView: App initialization complete (no session)")
            return
        }

        // Step 2: Realm 셋업 + 프로필 로드를 병렬로
        async let realmSetup: () = RealmManager.shared.setupRealm(for: userId.uuidString)
        async let profileLoad: () = loadUserProfile(userId: userId)
        _ = await (realmSetup, profileLoad)

        // Step 3: isNewUser 결정 후 데이터 로드
        if !authService.isNewUser {
            // 기존 유저: 데이터 + 캐릭터 병렬 로드
            async let dataLoad: () = dataStore.initialLoad()
            async let characterLoad: () = characterStore.loadAllCharacters()
            _ = await (dataLoad, characterLoad)

            // 아바타 프리페치는 백그라운드 (스플래시 차단하지 않음)
            let avatarURLs = characterStore.allCharacters
                .compactMap { $0.avatar_url }
                .filter { !$0.isEmpty }
                .prefix(5)
            if !avatarURLs.isEmpty {
                Task {
                    ImageCache.shared.prefetch(urls: Array(avatarURLs))
                }
            }

            print("✅ RootView: User data setup complete")
            print("  - Posts: \(dataStore.posts.count)")
            print("  - Characters: \(characterStore.allCharacters.count)")
        } else {
            // 신규 유저: 캐릭터만 로드
            await characterStore.loadAllCharacters()
            print("ℹ️ RootView: New user - loaded characters only")
            print("  - Characters: \(characterStore.allCharacters.count)")
        }

        // Step 4: 언어 동기화는 백그라운드
        Task {
            await localizationManager.syncWithUserProfile()
        }

        currentUserId = userId
        isInitialized = true
        print("✅ RootView: App initialization complete")
    }

    /// 프로필 로드 + isNewUser 판정
    private func loadUserProfile(userId: UUID) async {
        do {
            try await UserProfileStore.shared.fetchUserProfile(userId: userId)
            if let profile = UserProfileStore.shared.userProfile {
                await MainActor.run {
                    authService.isNewUser = profile.is_new
                    authService.isLoading = false
                }
            }
        } catch {
            Logger.debug("Failed to load user profile: \(error)")
            await MainActor.run {
                authService.isLoading = false
            }
        }
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

    /// 유저 전환 시 사용 (초기화와 별도)
    private func setupUserData(_ userId: UUID) async {
        await RealmManager.shared.setupRealm(for: userId.uuidString)

        if !authService.isNewUser {
            async let dataLoad: () = dataStore.initialLoad()
            async let characterLoad: () = characterStore.loadAllCharacters()
            _ = await (dataLoad, characterLoad)

            let urls = characterStore.allCharacters
                .compactMap { $0.avatar_url }
                .filter { !$0.isEmpty }
                .prefix(5)
            if !urls.isEmpty {
                Task {
                    ImageCache.shared.prefetch(urls: Array(urls))
                }
            }
        } else {
            await characterStore.loadAllCharacters()
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
    
}
