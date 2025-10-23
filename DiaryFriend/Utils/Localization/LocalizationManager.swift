//
//  LocalizationManager.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/21/25.
//

import Foundation
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    // ⭐ 언어 변경 시 모든 @Localized 자동 업데이트
    @Published var currentLanguage: AppLanguage = .english {
        didSet {
            loadCurrentBundle()
            Logger.debug("🌍 Language changed to: \(currentLanguage.rawValue)")
        }
    }
    
    private var bundle: Bundle = Bundle.main
    private let userDefaultsKey = "app_language"
    
    private init() {
        loadCurrentBundle()
    }
    
    // MARK: - Public Methods
    
    /// 앱 시작 시 호출: UserDefaults에서 언어 로드
    func loadSavedLanguage() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = AppLanguage(rawValue: saved) {
            currentLanguage = language
            Logger.debug("📱 Loaded language from UserDefaults: \(language.rawValue)")
        } else {
            // 시스템 언어 감지
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            currentLanguage = systemLanguage == "ko" ? .korean : .english
            Logger.debug("🌐 Using system language: \(currentLanguage.rawValue)")
        }
    }
    
    /// 언어 설정 및 저장
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: userDefaultsKey)
        Logger.debug("💾 Language saved: \(language.rawValue)")
    }
    
    /// UserProfile과 동기화
    func syncWithUserProfile() async {
        guard UserProfileStore.shared.isProfileLoaded else {
            Logger.debug("⏳ Profile not loaded yet, skipping sync")
            return
        }
        
        let isKorean = UserProfileStore.shared.isKoreanUser
        let profileLanguage: AppLanguage = isKorean ? .korean : .english
        
        if currentLanguage != profileLanguage {
            await MainActor.run {
                setLanguage(profileLanguage)
                Logger.debug("🔄 Synced with UserProfile: \(profileLanguage.rawValue)")
            }
        }
    }
    
    /// 번역 텍스트 반환
    func localized(_ key: LocalizationKey) -> String {
        let value = NSLocalizedString(key.rawValue, bundle: bundle, comment: "")
        
        #if DEBUG
        if value == key.rawValue {
            print("⚠️ Missing translation: \(key.rawValue)")
        }
        #endif
        
        return value == key.rawValue ? key.fallback : value
    }
    
    // MARK: - Private Methods
    
    private func loadCurrentBundle() {
        guard let path = Bundle.main.path(forResource: currentLanguage.code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            self.bundle = Bundle.main
            Logger.debug("⚠️ Failed to load bundle for \(currentLanguage.code)")
            return
        }
        self.bundle = bundle
        Logger.debug("✅ Loaded language bundle: \(currentLanguage.code)")
    }
}

// MARK: - Supporting Types

enum AppLanguage: String, CaseIterable, Codable {
    case english = "English"
    case korean = "Korean"
    
    var code: String {
        switch self {
        case .english: return "en"
        case .korean: return "ko"
        }
    }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
        }
    }
}
