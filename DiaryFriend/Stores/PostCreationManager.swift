//
//  PostCreationManager.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/21/25.
//

import Foundation

@MainActor
class PostCreationManager: ObservableObject {
    static let shared = PostCreationManager()
    private init() {}
    
    @Published var selectedDate: Date?
    @Published var selectedCharacterId: Int?  // 추가
    
    func setSelectedDate(_ date: Date) {
        self.selectedDate = date
    }
    
    func clearSelectedDate() {
        self.selectedDate = nil
    }
    
    func setSelectedCharacter(_ id: Int) {  // 추가
        self.selectedCharacterId = id
    }
    
    func clearAll() {  // 추가
        self.selectedDate = nil
        self.selectedCharacterId = nil
    }
}
