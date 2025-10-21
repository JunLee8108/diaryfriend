//
//  DiaryFriendApp.swift
//  DiaryFriend
//

import SwiftUI
import SwiftData

@main
struct DiaryFriendApp: App {
    init() {
        // Configuration 출력
        #if DEBUG
        Config.printConfiguration()
        // ⚠️ 테스트용: 기존 Realm 데이터 모두 삭제
//        cleanupOldRealmData()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(maxWidth: 500)
                .frame(maxWidth: .infinity)
        }
    }
    
    private func cleanupOldRealmData() {
        print("🧹 Starting Realm cleanup...")
        
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key.description)
        }
        
        var deletedFiles: [String] = []
        
        // 1. 기존 단일 파일 삭제
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask).first!
        let oldRealmPath = documentsPath.appendingPathComponent("DiaryFriend.realm")
        
        // 관련 파일들 모두 삭제 (.realm, .realm.lock, .realm.note, .realm.management)
        let extensions = ["", ".lock", ".note", ".management"]
        for ext in extensions {
            let filePath = oldRealmPath.path + ext
            if FileManager.default.fileExists(atPath: filePath) {
                do {
                    try FileManager.default.removeItem(atPath: filePath)
                    deletedFiles.append(filePath.components(separatedBy: "/").last ?? "")
                    print("  ✅ Deleted: \(filePath.components(separatedBy: "/").last ?? "")")
                } catch {
                    print("  ❌ Failed to delete: \(filePath) - \(error)")
                }
            }
        }
        
        // 2. UserData 디렉토리도 삭제 (깨끗하게 시작)
        let userDataPath = documentsPath.appendingPathComponent("UserData")
        if FileManager.default.fileExists(atPath: userDataPath.path) {
            do {
                try RealmConfiguration.shared.deleteAllUserRealms()
                print("  ✅ Deleted: UserData directory")
                deletedFiles.append("UserData/")
            } catch {
                print("  ❌ Failed to delete UserData: \(error)")
            }
        }
        
        // 3. 삭제 결과 요약
        if deletedFiles.isEmpty {
            print("📭 No Realm files found to delete (already clean)")
        } else {
            print("🗑️ Cleanup complete! Deleted \(deletedFiles.count) items:")
            deletedFiles.forEach { print("   - \($0)") }
        }
        
        print("✨ Ready for fresh start with user-specific Realm")
    }
}
