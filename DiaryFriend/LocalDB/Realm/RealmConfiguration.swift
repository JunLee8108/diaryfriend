//
//  RealmConfiguration.swift
//  DiaryFriend
//
//  Realm 초기 설정 및 마이그레이션 관리
//

import RealmSwift
import Foundation

class RealmConfiguration {
    static let shared = RealmConfiguration()
    private var currentUserId: String?
    
    private init() {}
    
    // 현재 스키마 버전
    private let schemaVersion: UInt64 = 1
    
    // MARK: - User-specific Configuration
    
    /// 사용자별 Realm Configuration 생성
    func configurationForUser(_ userId: String?) -> Realm.Configuration {
        var config = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                // 향후 마이그레이션 로직
                if oldSchemaVersion < 1 {
                    // v0 → v1 마이그레이션
                }
            },
            deleteRealmIfMigrationNeeded: false  // 프로덕션에서는 절대 false
        )
        
        if let userId = userId {
            // 사용자별 디렉토리 생성
            let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                         in: .userDomainMask).first!
            let userDataPath = documentsPath
                .appendingPathComponent("UserData")
                .appendingPathComponent(userId)
            
            // 디렉토리가 없으면 생성
            try? FileManager.default.createDirectory(
                at: userDataPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            // 사용자별 Realm 파일 경로
            config.fileURL = userDataPath.appendingPathComponent("data.realm")
            currentUserId = userId
            
            Logger.debug("📂 User Realm path: \(config.fileURL!.path)")
            Logger.debug("👤 User ID: \(userId.prefix(8))...")
            
        } else {
            // 로그아웃 상태 - 임시 메모리 DB 사용
            config.inMemoryIdentifier = "temp-\(UUID().uuidString)"
            currentUserId = nil
            print("💭 Using temporary in-memory Realm (no user)")
        }
        
        return config
    }
    
    // MARK: - Legacy Methods (Compatibility)
    
    /// 기본 Configuration (현재 사용자 기반)
    var configuration: Realm.Configuration {
        return configurationForUser(currentUserId)
    }
    
    /// Realm 파일 경로 (현재 사용자 기반)
    private func realmFileURL() -> URL? {
        return configuration.fileURL
    }
    
    /// 초기화 메서드 (레거시 호환용)
    func setupRealm() throws -> Realm {
        let config = self.configuration
        Realm.Configuration.defaultConfiguration = config
        
        do {
            let realm = try Realm()
            print("✅ Realm initialized successfully")
            if let fileURL = config.fileURL {
                print("📍 Realm file path: \(fileURL.path)")
            } else {
                print("📍 Using in-memory Realm")
            }
            print("📊 Schema version: \(schemaVersion)")
            return realm
        } catch {
            print("❌ Realm initialization failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Development Utilities
    
    /// 개발용: Realm 파일 경로 출력
    func printRealmPath() {
        if let fileURL = configuration.fileURL {
            print("📂 Realm file location:")
            print(fileURL.path)
        } else {
            print("📂 Using in-memory Realm (no file)")
        }
    }
    
    /// 캐시 크기 확인
    func getRealmFileSize() -> String {
        guard let fileURL = configuration.fileURL else {
            return "In-Memory (No file)"
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? NSNumber {
                let sizeInMB = fileSize.doubleValue / 1024 / 1024
                return String(format: "%.2f MB", sizeInMB)
            }
        } catch {
            print("❌ Failed to get file size: \(error)")
        }
        
        return "Unknown"
    }
    
    /// Realm 연결 테스트
    static func testConnection() -> Bool {
        do {
            _ = try shared.setupRealm()
            print("✅ Realm connection test successful")
            return true
        } catch {
            print("❌ Realm connection test failed: \(error)")
            return false
        }
    }
    
    // MARK: - User Management
    
    /// 사용자 Realm 파일 삭제 (선택사항)
    func deleteUserRealmFile(_ userId: String) throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask).first!
        let userDataPath = documentsPath
            .appendingPathComponent("UserData")
            .appendingPathComponent(userId)
        
        if FileManager.default.fileExists(atPath: userDataPath.path) {
            try FileManager.default.removeItem(at: userDataPath)
            print("🗑️ Deleted Realm data for user \(userId.prefix(8))")
        }
    }
    
    /// 모든 사용자 데이터 삭제 (개발용)
    func deleteAllUserRealms() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask).first!
        let userDataPath = documentsPath.appendingPathComponent("UserData")
        
        if FileManager.default.fileExists(atPath: userDataPath.path) {
            try FileManager.default.removeItem(at: userDataPath)
            print("🗑️ Deleted all user Realm data")
        }
    }
}
