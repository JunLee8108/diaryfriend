//
//  SupabaseManager.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/16/25.
//

import Foundation
import Supabase

class SupabaseManager: ObservableObject {
    // 싱글톤 (앱 전체에서 하나만 존재)
    static let shared = SupabaseManager()
    
    // Supabase 클라이언트
    let client: SupabaseClient
    
    // 현재 로그인한 유저
    @Published var currentUser: User?
    
    private init() {
        // Config에서 설정값 가져와서 연결
        self.client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
        
        print("✅ Supabase 연결 완료")
        
        // 세션 체크
        Task {
            await checkSession()
        }
    }
    
    // 세션 확인 및 유저 정보 업데이트
    private func checkSession() async {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.currentUser = session.user
            }
        } catch {
            print("No active session")
        }
    }
    
    // 유저 정보 업데이트 메서드
    func updateCurrentUser(_ user: User?) {
        self.currentUser = user
    }
}
