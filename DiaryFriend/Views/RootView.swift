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
    
    // ⭐ LocalizationManager EnvironmentObject로 받기
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var isInitialized = false
    @State private var currentUserId: UUID?
    
    @State private var showLaunchScreen = true
    @State private var showSessionExpiredModal = false
    @State private var expiredUserId: UUID?
    
    // ⭐ 다국어 적용
    @Localized(.session_expired_title) var sessionExpiredTitle
    @Localized(.session_expired_message) var sessionExpiredMessage
    @Localized(.common_ok) var okButton
    
    var body: some View {
        ZStack {
            Group {
                if authService.isLoading {
                    LoadingView()
                } else if authService.isAuthenticated {
                    MainView()
                        .environmentObject(authService)
                        .environmentObject(userProfileStore)
                        .environmentObject(dataStore)
                        .environmentObject(statsDataStore)
                        .environmentObject(characterStore)
                } else {
                    LoginView()
                        .environmentObject(authService)
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
        .task {
            guard !isInitialized else { return }
            
            async let initTask: () = initializeApp()
            async let minDisplayTask: () = {
                try? await Task.sleep(nanoseconds: 300_000_000)
            }()
            
            _ = await (initTask, minDisplayTask)
            
            withAnimation(.easeOut(duration: 0.5)) {
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
            title: sessionExpiredTitle,        // ⭐ 다국어 적용
            message: sessionExpiredMessage,     // ⭐ 다국어 적용
            icon: "exclamationmark.triangle",
            iconColor: Color(hex: "FF9800"),
            buttonText: okButton,               // ⭐ 다국어 적용
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
            // 프로필 로딩과 데이터 설정을 병렬 실행
            async let profileTask: () = loadUserProfile(userId: userId)
            async let setupTask: () = setupUserData(userId)
            _ = await (profileTask, setupTask)

            currentUserId = userId

            // ⭐ 인증 후 UserProfile과 언어 동기화
            await localizationManager.syncWithUserProfile()
        }

        isInitialized = true
        print("✅ RootView: App initialization complete")
    }

    private func loadUserProfile(userId: UUID) async {
        do {
            try await UserProfileStore.shared.fetchUserProfile(userId: userId)
            Logger.debug("User profile loaded successfully")
        } catch {
            Logger.debug("Failed to load user profile: \(error)")
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
        
        // Realm 삭제
        do {
            try RealmConfiguration.shared.deleteUserRealmFile(userId.uuidString)
            print("✅ Realm file deleted due to session expiration")
        } catch {
            print("⚠️ Failed to delete Realm file: \(error)")
        }
        
        // 로그아웃
        try? await authService.signOut()
        
        // 정리
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
            
            // ⭐ 사용자 변경 시에도 언어 동기화
            await localizationManager.syncWithUserProfile()
        }
        
        currentUserId = newUserId
    }
    
    // MARK: - User Data Management
    
    private func setupUserData(_ userId: UUID) async {
        Logger.debug("🚀 Setting up Realm, data, and character for user \(userId.uuidString.prefix(8))...")
        
        await RealmManager.shared.setupRealm(for: userId.uuidString)
        
        async let dataLoad: () = dataStore.initialLoad()
        async let characterLoad: () = characterStore.loadAllCharacters()
        _ = await (dataLoad, characterLoad)
        
        prefetchAvatars()
        
        print("✅ RootView: User data setup complete")
        print("  - Posts: \(dataStore.posts.count)")
        print("  - Characters: \(characterStore.allCharacters.count)")
    }
    
    private func clearUserData() async {
        print("🧹 RootView: Clearing previous user data...")
        
        await dataStore.clearAllData()
        await characterStore.clearAllData()
        await UserProfileStore.shared.clearProfile()
        
        await MainActor.run {
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

// MARK: - Loading View
struct LoadingView: View {
    // ⭐ 다국어 적용
    @Localized(.app_diary_friend) var appName
    @Localized(.app_loading) var loadingText
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(appName)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(loadingText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    RootView()
        .environmentObject(LocalizationManager.shared)
}
