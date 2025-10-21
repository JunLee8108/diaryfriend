//
//  PostChangeNotification.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/7/25.
//

//
//  PostChangeNotification.swift
//  DiaryFriend
//
//  포스트 변경 이벤트 정의
//

import Foundation

// MARK: - Post Change Event
enum PostChangeEvent {
    case created(postId: Int, date: String)
    case updated(postId: Int, date: String)
    case deleted(postId: Int, date: String)
}

// MARK: - Notification Names
extension Notification.Name {
    static let postDidChange = Notification.Name("postDidChange")
}

// MARK: - Notification Keys
struct PostChangeNotificationKey {
    static let event = "event"
    static let postId = "postId"
    static let date = "date"
}

// MARK: - Post Change Manager
class PostChangeManager {
    static let shared = PostChangeManager()
    
    private init() {}
    
    /// 포스트 생성 이벤트 발송
    func notifyPostCreated(postId: Int, date: String) {
        notify(event: .created(postId: postId, date: date))
        print("📢 PostChange: Created - ID \(postId), Date \(date)")
    }
    
    /// 포스트 업데이트 이벤트 발송
    func notifyPostUpdated(postId: Int, date: String) {
        notify(event: .updated(postId: postId, date: date))
        print("📢 PostChange: Updated - ID \(postId), Date \(date)")
    }
    
    /// 포스트 삭제 이벤트 발송
    func notifyPostDeleted(postId: Int, date: String) {
        notify(event: .deleted(postId: postId, date: date))
        print("📢 PostChange: Deleted - ID \(postId), Date \(date)")
    }
    
    // MARK: - Private
    
    private func notify(event: PostChangeEvent) {
        let (postId, date) = extractEventData(event)
        
        NotificationCenter.default.post(
            name: .postDidChange,
            object: nil,
            userInfo: [
                PostChangeNotificationKey.event: event,
                PostChangeNotificationKey.postId: postId,
                PostChangeNotificationKey.date: date
            ]
        )
    }
    
    private func extractEventData(_ event: PostChangeEvent) -> (Int, String) {
        switch event {
        case .created(let postId, let date),
             .updated(let postId, let date),
             .deleted(let postId, let date):
            return (postId, date)
        }
    }
}
