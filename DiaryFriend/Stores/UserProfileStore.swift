// Stores/UserProfileStore.swift

import Foundation
import Supabase

// MARK: - Models
struct UserProfile: Codable {
    let id: UUID
    let display_name: String?
    let language: String
    let created_at: Date
    let updated_at: Date?
    /// Premium(광고 제거) 구독 상태. 기본값 false.
    /// 서버(Supabase User_Profile 테이블)의 is_premium 컬럼과 매핑됩니다.
    /// 신규 컬럼이므로 구 버전 레코드에서 누락될 수 있어 옵셔널로 선언.
    let is_premium: Bool?
}

enum Language: String, CaseIterable {
    case english = "English"
    case korean = "Korean"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
        }
    }
}

// MARK: - Error
enum ProfileError: LocalizedError {
    case notLoaded
    case fetchFailed(String)
    case updateFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notLoaded:
            return "User profile not loaded"
        case .fetchFailed(let message):
            return "Failed to fetch profile: \(message)"
        case .updateFailed(let message):
            return "Failed to update profile: \(message)"
        }
    }
}

// MARK: - Store
class UserProfileStore: ObservableObject {
    static let shared = UserProfileStore()
    private let supabase = SupabaseManager.shared.client
    
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {}
    
    // MARK: - Fetch Profile
    func fetchUserProfile(userId: UUID) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let profile: UserProfile = try await supabase
                .from("User_Profile")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.userProfile = profile
                self.isLoading = false
            }
        } catch {
            let errorMessage = error.localizedDescription
            await MainActor.run {
                self.error = errorMessage
                self.isLoading = false
            }
            throw ProfileError.fetchFailed(errorMessage)
        }
    }
    
    // MARK: - Update Display Name
    func updateDisplayName(_ displayName: String) async throws {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🟢 updateDisplayName called with: \(trimmedName)")
        
        guard !trimmedName.isEmpty else {
            print("❌ Name is empty")
            throw ProfileError.updateFailed("Display name cannot be empty")
        }
        
        guard trimmedName.count <= 30 else {
            print("❌ Name too long: \(trimmedName.count)")
            throw ProfileError.updateFailed("Display name must be 30 characters or less")
        }
        
        guard let userId = userProfile?.id else {
            print("❌ User profile not loaded")
            throw ProfileError.notLoaded
        }
        
        print("🔄 Updating display name to: \(trimmedName)")
        print("📱 User ID: \(userId.uuidString)")
        
        await MainActor.run {
            print("🟡 Setting isLoading = true")
            isLoading = true
            error = nil
        }
        
        do {
            print("📦 Preparing update data...")
            let updateData: [String: String] = [
                "display_name": trimmedName,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            print("📦 Update data prepared: \(updateData)")
            
            print("📤 Sending update request to Supabase...")
            try await supabase
                .from("User_Profile")
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .execute()
            
            print("✅ Supabase update completed")
            
            print("🔄 Fetching updated profile...")
            try await fetchUserProfile(userId: userId)
            
            print("✅ Display name updated successfully")
            
            await MainActor.run {
                print("🟢 Setting isLoading = false")
                self.isLoading = false
            }
            
        } catch {
            print("❌ Update failed with error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            
            let errorMessage = error.localizedDescription
            await MainActor.run {
                print("🔴 Setting error state")
                self.error = errorMessage
                self.isLoading = false
            }
            throw ProfileError.updateFailed(errorMessage)
        }
    }
    
    // MARK: - Update Language
    func updateLanguage(_ language: String) async throws {
        guard Language(rawValue: language) != nil else {
            throw ProfileError.updateFailed("Invalid language selection")
        }
        
        guard let userId = userProfile?.id else {
            throw ProfileError.notLoaded
        }
        
        if userProfile?.language == language {
            return
        }
        
        print("🔄 Updating language to: \(language)")
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let updateData: [String: String] = [
                "language": language,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            try await supabase
                .from("User_Profile")
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .execute()
            
            print("✅ User_Profile updated")
            
            try await fetchUserProfile(userId: userId)
            
            // ⭐ LocalizationManager와 동기화
            await MainActor.run {
                let appLanguage: AppLanguage = (language == "Korean") ? .korean : .english
                LocalizationManager.shared.setLanguage(appLanguage)
            }
            
            print("✅ Language updated successfully")
            
            await MainActor.run {
                self.isLoading = false
            }
            
        } catch {
            print("❌ Update failed: \(error)")
            let errorMessage = error.localizedDescription
            await MainActor.run {
                self.error = errorMessage
                self.isLoading = false
            }
            throw ProfileError.updateFailed(errorMessage)
        }
    }
    
    // MARK: - Update Profile (Both fields)
    func updateProfile(displayName: String? = nil, language: String? = nil) async throws {
        guard let userId = userProfile?.id else {
            throw ProfileError.notLoaded
        }
        
        guard displayName != nil || language != nil else {
            return
        }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            var updateData: [String: String] = [:]
            
            if let displayName = displayName {
                let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty && trimmedName.count <= 30 else {
                    throw ProfileError.updateFailed("Invalid display name")
                }
                updateData["display_name"] = trimmedName
            }
            
            if let language = language {
                guard Language(rawValue: language) != nil else {
                    throw ProfileError.updateFailed("Invalid language")
                }
                updateData["language"] = language
            }
            
            updateData["updated_at"] = ISO8601DateFormatter().string(from: Date())
            
            try await supabase
                .from("User_Profile")
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .execute()
            
            try await fetchUserProfile(userId: userId)
            
            await MainActor.run {
                self.isLoading = false
            }
            
        } catch {
            let errorMessage = error.localizedDescription
            await MainActor.run {
                self.error = errorMessage
                self.isLoading = false
            }
            throw ProfileError.updateFailed(errorMessage)
        }
    }
    
    // MARK: - Clear Profile
    @MainActor
    func clearProfile() async {
        userProfile = nil
        error = nil
        isLoading = false
    }
}

// MARK: - Convenience Extensions
extension UserProfileStore {
    var currentDisplayName: String {
        userProfile?.display_name ?? "User"
    }
    
    var currentLanguage: Language? {
        guard let langString = userProfile?.language else { return nil }
        return Language(rawValue: langString)
    }
    
    var isKoreanUser: Bool {
        currentLanguage == .korean
    }
    
    var isProfileLoaded: Bool {
        userProfile != nil
    }

    /// 프리미엄(광고 제거) 구독자 여부. 미로드 / 미구독 / 컬럼 누락은 모두 false로 취급.
    var isPremium: Bool {
        userProfile?.is_premium ?? false
    }
}
