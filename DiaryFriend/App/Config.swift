//
//  Config.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/16/25.
//

import Foundation

enum Config {
    // MARK: - Supabase Configuration
    static var supabaseURL: String {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !urlString.isEmpty else {
            fatalError("""
                ⚠️ SUPABASE_URL이 설정되지 않았습니다.
                1. Development.xcconfig 파일 생성
                2. SUPABASE_URL 값 설정
                3. Project Settings에서 Configuration 연결
                """)
        }
        return urlString
    }
    
    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else {
            fatalError("""
                ⚠️ SUPABASE_ANON_KEY가 설정되지 않았습니다.
                1. Development.xcconfig 파일 생성
                2. SUPABASE_ANON_KEY 값 설정
                3. Project Settings에서 Configuration 연결
                """)
        }
        return key
    }
    
    // MARK: - AdMob Configuration
    enum AdMob {
        /// Info.plist에서 읽어오는 AdMob App ID (xcconfig → GADApplicationIdentifier)
        static var appID: String {
            guard let id = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String,
                  !id.isEmpty else {
                assertionFailure("⚠️ GADApplicationIdentifier가 Info.plist에 설정되지 않았습니다.")
                return ""
            }
            return id
        }

        /// Home 화면 배너 광고 단위 ID.
        /// DEBUG에서는 Google이 제공하는 공식 테스트 ID를 사용합니다.
        /// 실광고 클릭은 AdMob 계정 정지 사유이므로 개발 중에는 절대 실제 ID를 사용하지 마세요.
        static var homeBannerUnitID: String {
            #if DEBUG
            return "ca-app-pub-3940256099942544/2934735716"  // Google sample banner
            #else
            return "ca-app-pub-1269905910712091/7101710563"
            #endif
        }
    }

    // MARK: - Environment
    enum Environment {
        case development
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
        
        var name: String {
            switch self {
            case .development: return "개발"
            case .production: return "운영"
            }
        }
    }
    
    // MARK: - Debugging Helper
    static func printConfiguration() {
        #if DEBUG
        print("""
        ========================================
        📱 DiaryFriend Configuration
        ========================================
        Environment: \(Environment.current.name)
        Supabase URL: \(supabaseURL)
        API Key: \(String(supabaseAnonKey.prefix(20)))...
        ========================================
        """)
        #endif
    }
}

