//
//  PostObject.swift
//  DiaryFriend
//
//  LocalDB/Realm/Models/PostObject.swift
//  Post 데이터 Realm 모델
//

import Foundation
import RealmSwift

// MARK: - Post Realm Object
class PostObject: Object {
    // Primary Fields
    @Persisted var id: Int = 0
    @Persisted var content: String = ""
    @Persisted var mood: String?
    @Persisted var entryDate: String = ""
    @Persisted var createdAt: String = ""
    @Persisted var updatedAt: String?
    @Persisted var userId: String = ""
    
    // AI Processing
    @Persisted var allowAiComments: Bool = true
    @Persisted var aiProcessingStatus: String?
    @Persisted var aiGenerated: Bool = false  // ✅ 추가
    
    // Relationships
    @Persisted var comments = List<CommentObject>()
    @Persisted var hashtags = List<String>()
    @Persisted var images = List<ImageObject>()
    
    // Metadata
    @Persisted var lastSynced: Date = Date()
    @Persisted var isCached: Bool = false
    
    // Primary Key
    override static func primaryKey() -> String? {
        return "id"
    }
    
    // Indexed Properties
    override static func indexedProperties() -> [String] {
        return ["entryDate", "userId", "createdAt"]
    }
}

// MARK: - Comment Embedded Object
class CommentObject: EmbeddedObject {
    @Persisted var id: Int = 0
    @Persisted var characterId: Int = 0
    @Persisted var message: String = ""
    @Persisted var createdAt: String = ""
}

// MARK: - Image Embedded Object (UUID 버전)
class ImageObject: EmbeddedObject {
    @Persisted var id: String = ""  // UUID → String
    @Persisted var storagePath: String = ""
    @Persisted var displayOrder: Int = 0
    @Persisted var fileSize: Int?
    @Persisted var createdAt: String = ""
}

// MARK: - Conversion Extensions
extension PostObject {
    /// Realm → Post (기본)
    func toPost() -> Post {
        return Post(
            id: id,
            content: content,
            mood: mood,
            entry_date: entryDate,
            created_at: createdAt,
            user_id: UUID(uuidString: userId) ?? UUID(),
            ai_generated: aiGenerated  // ✅ 추가
        )
    }
    
    /// Realm → PostDetail (상세)
    func toPostDetail() -> PostDetail {
        // Comments 변환
        let commentArray: [Comment]? = comments.isEmpty ? nil : comments.map { commentObj in
            Comment(
                id: commentObj.id,
                character_id: commentObj.characterId,
                message: commentObj.message,
                created_at: commentObj.createdAt
            )
        }
        
        // Hashtags 변환
        let postHashtags: [PostHashtag]? = hashtags.isEmpty ? nil : hashtags.enumerated().map { (index, tag) in
            PostHashtag(
                hashtag_id: index,
                Hashtag: Hashtag(name: tag)
            )
        }
        
        // Images 변환 (UUID 버전)
        let imageArray: [PostImageInfo]? = images.isEmpty ? nil : images.map { imgObj in
            PostImageInfo(
                id: imgObj.id,  // String (UUID)
                storagePath: imgObj.storagePath,
                displayOrder: imgObj.displayOrder,
                fileSize: imgObj.fileSize,
                createdAt: imgObj.createdAt
            )
        }
        
        return PostDetail(
            id: id,
            content: content,
            mood: mood,
            allow_ai_comments: allowAiComments,
            ai_processing_status: aiProcessingStatus,
            ai_generated: aiGenerated,  // ✅ 추가
            entry_date: entryDate,
            created_at: createdAt,
            updated_at: updatedAt,
            user_id: UUID(uuidString: userId) ?? UUID(),
            Comment: commentArray,
            Post_Hashtag: postHashtags,
            Image: imageArray
        )
    }
}

// MARK: - Domain Model to Realm Conversions
extension Post {
    /// Post → Realm Object
    func toRealmObject(userId: String? = nil) -> PostObject {
        let realmObject = PostObject()
        
        realmObject.id = id
        realmObject.content = content
        realmObject.mood = mood
        realmObject.entryDate = entry_date
        realmObject.createdAt = created_at
        realmObject.aiGenerated = ai_generated ?? false  // ✅ 추가
        
        // User ID
        if let userId = userId {
            realmObject.userId = userId
        } else {
            realmObject.userId = user_id.uuidString
        }
        
        realmObject.lastSynced = Date()
        realmObject.isCached = false
        
        return realmObject
    }
}

extension PostDetail {
    /// PostDetail → Realm Object
    func toRealmObject(userId: String? = nil) -> PostObject {
        let realmObject = PostObject()
        
        // Basic fields
        realmObject.id = id
        realmObject.content = content
        realmObject.mood = mood
        realmObject.entryDate = entry_date
        realmObject.createdAt = created_at
        realmObject.updatedAt = updated_at
        realmObject.allowAiComments = allow_ai_comments ?? true
        realmObject.aiProcessingStatus = ai_processing_status
        realmObject.aiGenerated = ai_generated ?? false  // ✅ 추가
        
        // User ID
        if let userId = userId {
            realmObject.userId = userId
        } else {
            realmObject.userId = user_id.uuidString
        }
        
        // Comments
        if let comments = Comment {
            realmObject.comments.removeAll()
            for comment in comments {
                let commentObj = CommentObject()
                commentObj.id = comment.id
                commentObj.characterId = comment.character_id
                commentObj.message = comment.message
                commentObj.createdAt = comment.created_at
                realmObject.comments.append(commentObj)
            }
        }
        
        // Hashtags
        if let hashtags = Post_Hashtag?.compactMap({ $0.Hashtag?.name }) {
            realmObject.hashtags.removeAll()
            realmObject.hashtags.append(objectsIn: hashtags)
        }
        
        // Images (UUID 버전)
        if let images = Image {
            realmObject.images.removeAll()
            for image in images {
                let imgObj = ImageObject()
                imgObj.id = image.id  // String (UUID)
                imgObj.storagePath = image.storagePath
                imgObj.displayOrder = image.displayOrder
                imgObj.fileSize = image.fileSize
                imgObj.createdAt = image.createdAt
                realmObject.images.append(imgObj)
            }
        }
        
        realmObject.lastSynced = Date()
        realmObject.isCached = true
        
        return realmObject
    }
}

// MARK: - Query Helpers
extension PostObject {
    /// 특정 월의 포스트 조회
    static func postsForMonth(_ monthKey: String, userId: String, in realm: Realm) -> Results<PostObject> {
        return realm.objects(PostObject.self)
            .filter("userId == %@ AND entryDate BEGINSWITH %@", userId, monthKey)
            .sorted(byKeyPath: "entryDate", ascending: false)
    }
    
    /// 날짜 범위로 포스트 조회
    static func postsInRange(from: String, to: String, userId: String, in realm: Realm) -> Results<PostObject> {
        return realm.objects(PostObject.self)
            .filter("userId == %@ AND entryDate >= %@ AND entryDate <= %@", userId, from, to)
            .sorted(byKeyPath: "entryDate", ascending: false)
    }
    
    /// 특정 날짜의 포스트 조회
    static func postsForDate(_ dateString: String, userId: String, in realm: Realm) -> Results<PostObject> {
        return realm.objects(PostObject.self)
            .filter("userId == %@ AND entryDate == %@", userId, dateString)
            .sorted(byKeyPath: "createdAt", ascending: false)
    }
    
    /// 동기화 필요 체크
    func needsSync(threshold: TimeInterval = 3600) -> Bool {
        return Date().timeIntervalSince(lastSynced) > threshold
    }
    
    /// 캐시 신선도 체크
    func isFresh(threshold: TimeInterval = 1800) -> Bool {
        return Date().timeIntervalSince(lastSynced) < threshold
    }
}

// MARK: - Batch Operations
extension PostObject {
    /// 캐시 상태 업데이트
    func markAsCached() {
        self.isCached = true
        self.lastSynced = Date()
    }
    
    /// 동기화 시간 업데이트
    func updateSyncTime() {
        self.lastSynced = Date()
    }
}
