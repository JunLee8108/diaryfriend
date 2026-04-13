import Foundation
import Supabase
import AuthenticationServices

class AuthService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    @Published var session: Session?
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var isNewUser = false
    
    func initialize() async {
        await checkSession()
    }

    // MARK: - Lightweight Session Check (세션만 확인, 프로필 로드 안 함)
    func checkSessionOnly() async {
        do {
            let session = try await supabase.auth.session

            await MainActor.run {
                self.session = session
                self.currentUser = session.user
                self.isAuthenticated = true

                SupabaseManager.shared.updateCurrentUser(session.user)
            }

            Logger.debug("⚡ Session restored (lightweight)")

        } catch {
            await MainActor.run {
                self.session = nil
                self.currentUser = nil
                self.isAuthenticated = false
                self.isLoading = false

                SupabaseManager.shared.updateCurrentUser(nil)
            }

            await UserProfileStore.shared.clearProfile()
        }
    }

    // MARK: - Session Check (Full - 프로필 포함)
    func checkSession() async {
        do {
            let session = try await supabase.auth.session

            await MainActor.run {
                self.session = session
                self.currentUser = session.user
                self.isAuthenticated = true

                SupabaseManager.shared.updateCurrentUser(session.user)
            }

            let userId = session.user.id

            Logger.debug("Loading user profile for existing session...")

            do {
                try await UserProfileStore.shared.fetchUserProfile(userId: userId)
                Logger.debug("User profile loaded successfully")

                // ✅ is_new 체크 추가
                if let profile = UserProfileStore.shared.userProfile {
                    await MainActor.run {
                        self.isNewUser = profile.is_new
                        print("📊 Session restored - isNewUser: \(profile.is_new)")
                    }
                }

            } catch {
                Logger.debug("Failed to load user profile: \(error)")
            }

            await MainActor.run {
                self.isLoading = false
            }

        } catch {
            await MainActor.run {
                self.session = nil
                self.currentUser = nil
                self.isAuthenticated = false
                self.isLoading = false

                SupabaseManager.shared.updateCurrentUser(nil)
            }

            await UserProfileStore.shared.clearProfile()
        }
    }
    
    // MARK: - Apple Sign In
    func signInWithApple() async throws {
        print("Apple sign in attempt...")
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            try await supabase.auth.signInWithOAuth(
                provider: .apple,
                redirectTo: URL(string: "diaryfriend://auth-callback")
            ) { session in
                session.prefersEphemeralWebBrowserSession = false
            }

            try await handleOAuthSuccess()

        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            throw AuthError.signInFailed("Failed to sign in with Apple")
        }
    }

    // MARK: - Google Sign In
    func signInWithGoogle() async throws {
        print("Google sign in attempt...")

        await MainActor.run {
            self.isLoading = true
        }

        do {
            try await supabase.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "diaryfriend://auth-callback"),
                queryParams: [("prompt", "select_account")]
            ) { session in
                session.prefersEphemeralWebBrowserSession = false
            }

            try await handleOAuthSuccess()

        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            throw AuthError.signInFailed("Failed to sign in with Google")
        }
    }
    
    // MARK: - OAuth Success Handler
    private func handleOAuthSuccess() async throws {
        do {
            let session = try await supabase.auth.session
            
            print("Session created for: \(session.user.email ?? "unknown")")
            
            await MainActor.run {
                self.session = session
                self.currentUser = session.user
                self.isAuthenticated = true
                
                SupabaseManager.shared.updateCurrentUser(session.user)
            }
            
            let userId = session.user.id
            let isNew = await checkIfNewUser(session.user)
            
            await MainActor.run {
                self.isNewUser = isNew
            }
            
            if !isNew {
                do {
                    try await UserProfileStore.shared.fetchUserProfile(userId: userId)
                    print("User authenticated")
                } catch {
                    print("Failed to load user profile: \(error)")
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
            
        } catch {
            print("OAuth handling failed: \(error)")
            
            await MainActor.run {
                self.isLoading = false
            }
            
            throw AuthError.signInFailed("Authentication failed. Please try signing in.")
        }
    }
    
    // MARK: - Deep Link Handling
    func handleDeepLink(_ url: URL) async throws {
        print("Handling deep link: \(url)")
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let session = try await supabase.auth.session(from: url)
            
            print("Session created for: \(session.user.email ?? "unknown")")
            
            await MainActor.run {
                self.session = session
                self.currentUser = session.user
                self.isAuthenticated = true
                
                SupabaseManager.shared.updateCurrentUser(session.user)
            }
            
            let userId = session.user.id
            let isNew = await checkIfNewUser(session.user)
            
            await MainActor.run {
                self.isNewUser = isNew
            }
            
            if !isNew {
                do {
                    try await UserProfileStore.shared.fetchUserProfile(userId: userId)
                    print("User authenticated")
                } catch {
                    print("Failed to load user profile: \(error)")
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
            
        } catch {
            print("Deep link handling failed: \(error)")
            
            await MainActor.run {
                self.isLoading = false
            }
            
            throw AuthError.signInFailed("Authentication failed. Please try signing in.")
        }
    }
    
    // MARK: - Sign Out
    func signOut() async throws {
        print("Signing out...")
        
        do {
            try await supabase.auth.signOut()
            print("✅ Supabase sign out successful")
        } catch {
            print("⚠️ Supabase sign out failed (session may be missing): \(error)")
            print("→ Continuing with local sign out...")
        }
        
        await MainActor.run {
            self.session = nil
            self.currentUser = nil
            self.isAuthenticated = false
            self.isNewUser = false
            
            SupabaseManager.shared.updateCurrentUser(nil)
            print("✅ Local sign out completed")
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        let isConnected = await MainActor.run {
            NetworkMonitor.shared.isConnected
        }
        
        guard isConnected else {
            print("❌ Cannot delete account: No internet connection")
            throw AuthError.networkRequired
        }
        
        guard let userId = currentUserId else {
            throw AuthError.notAuthenticated
        }
        
        print("🗑️ Starting account deletion process...")
        
        do {
            try await createDeleteRequest(userId: userId)
            print("✅ Delete request sent to server")
            
            try RealmConfiguration.shared.deleteUserRealmFile(userId.uuidString)
            print("✅ Realm file deleted")
            
            try await signOut()
            print("✅ Signed out successfully")
            
            print("🎉 Account deletion completed")
            
        } catch {
            print("❌ Account deletion failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Helpers
    private func createDeleteRequest(userId: UUID) async throws {
        struct DeleteRequest: Codable {
            let user_id: String
            let status: String
        }
        
        let request = DeleteRequest(
            user_id: userId.uuidString,
            status: "pending"
        )
        
        try await supabase
            .from("delete_requests")
            .insert(request)
            .execute()
        
        print("📤 Delete request created: \(userId.uuidString.prefix(8))")
    }
    
    // MARK: - Refresh Session
    func refreshSession() async throws {
        do {
            let session = try await supabase.auth.session
            
            await MainActor.run {
                self.session = session
                self.currentUser = session.user
                self.isAuthenticated = true
            }
            
            let userId = session.user.id
            try await UserProfileStore.shared.fetchUserProfile(userId: userId)
            
            // ✅ is_new 체크 추가
            if let profile = UserProfileStore.shared.userProfile {
                await MainActor.run {
                    self.isNewUser = profile.is_new
                }
            }
            
        } catch {
            try? await signOut()
            throw error
        }
    }
    
    // MARK: - Helper Methods
    private func checkIfNewUser(_ user: User) async -> Bool {
        for attempt in 1...3 {
            do {
                try await UserProfileStore.shared.fetchUserProfile(userId: user.id)
                
                let isNew = UserProfileStore.shared.userProfile?.is_new ?? false
                
                print("📊 User profile loaded (attempt \(attempt))")
                print("   - is_new: \(isNew)")
                print("   - created_at: \(UserProfileStore.shared.userProfile?.created_at ?? Date())")
                
                return isNew
                
            } catch {
                if attempt < 3 {
                    print("⏳ Waiting for profile creation... (attempt \(attempt)/3)")
                    try? await Task.sleep(nanoseconds: 500_000_000)
                } else {
                    print("❌ Profile not found after 3 attempts")
                    return false
                }
            }
        }
        return false
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case signInFailed(String)
    case profileFetchFailed(String)
    case notAuthenticated
    case networkRequired

    var errorDescription: String? {
        let loc = LocalizationManager.shared

        switch self {
        case .signInFailed(let message):
            return message
        case .profileFetchFailed(let message):
            return message
        case .notAuthenticated:
            return loc.localized(.error_not_authenticated)
        case .networkRequired:
            return loc.localized(.error_network_required)
        }
    }
}

// MARK: - Helper Extensions
extension AuthService {
    var currentUserId: UUID? {
        currentUser?.id
    }
    
    var currentUserEmail: String? {
        currentUser?.email
    }
    
    var isFullyLoaded: Bool {
        isAuthenticated && UserProfileStore.shared.isProfileLoaded
    }
    
    var displayName: String {
        if let profileName = UserProfileStore.shared.userProfile?.display_name {
            return profileName
        }
        return currentUserEmail ?? "User"
    }
}
