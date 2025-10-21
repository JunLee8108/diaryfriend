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
    
    @State private var isInitialized = false
    @State private var currentUserId: UUID?
    
    @State private var showLaunchScreen = true
    @State private var showSessionExpiredModal = false
    @State private var expiredUserId: UUID?  // ← 추가
    
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
                try? await Task.sleep(nanoseconds: 1_000_000_000)
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
            title: "Session Expired",
            message: "Your session has expired. Please sign in again to continue.",
            icon: "exclamationmark.triangle",
            iconColor: Color(hex: "FF9800"),
            buttonText: "OK",
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
                expiredUserId = userId  // ← 변경
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
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("DiaryFriend")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    RootView()
}
