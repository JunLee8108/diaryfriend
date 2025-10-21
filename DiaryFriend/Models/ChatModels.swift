//
//  ChatModels.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/24/25.
//
// Models/ChatModels.swift

import Foundation

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let sender: MessageSender
    let content: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case sender
        case content
        case timestamp = "created_at"  // DB의 created_at을 timestamp로 매핑
    }
    
    init(id: UUID = UUID(), sender: MessageSender, content: String, timestamp: Date = Date()) {
        self.id = id
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - Message Sender
enum MessageSender: String, Codable {
    case user = "user"
    case ai = "assistant"
    case system = "system"
    
    // Raw value for API compatibility
    var apiValue: String {
        return self.rawValue
    }
}
