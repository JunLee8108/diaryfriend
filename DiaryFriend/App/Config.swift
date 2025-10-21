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

