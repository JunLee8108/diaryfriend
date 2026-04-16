//
//  PostService.swift
//  DiaryFriend
//
//  Supabase Post 테이블과 통신
//  네트워크 통신만 담당 (비즈니스 로직은 DataStore에서)
//  DateUtility를 사용하여 날짜 처리 통합
//

import Foundation
import Supabase

// MARK: - Models

struct Comment: Codable {
    let id: Int
    let character_id: Int
    let message: String
    let created_at: String
}

// MARK: - Image Model (추가)

struct PostImageInfo: Codable {
    let id: String
    let storagePath: String
    let displayOrder: Int
    let fileSize: Int?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case storagePath = "storage_path"
        case displayOrder = "display_order"
        case fileSize = "file_size"
        case createdAt = "created_at"
    }
}

// MARK: - PostDetail (Image 필드 추가)

struct PostDetail: Codable {
    let id: Int
    let content: String
    let mood: String?
    let allow_ai_comments: Bool?
    let ai_processing_status: String?
    let ai_generated: Bool?
    let entry_date: String
    let created_at: String
    let updated_at: String?
    let user_id: UUID
    let Comment: [Comment]?
    let Post_Hashtag: [PostHashtag]?
    let Image: [PostImageInfo]?  // 추가
    
    var plainContent: String {
        if #available(iOS 15.0, *) {
            return content.htmlToPlainText()
        } else {
            return content.removingHTMLTags()
        }
    }
    
    var hashtags: [String] {
        Post_Hashtag?.compactMap { $0.Hashtag?.name } ?? []
    }
    
    // 이미지 경로 배열 (편의 속성)
    var imagePaths: [String] {
        Image?.sorted { $0.displayOrder < $1.displayOrder }
            .map { $0.storagePath } ?? []
    }
}

struct PostHashtag: Codable {
    let hashtag_id: Int
    let Hashtag: Hashtag?
}

struct Hashtag: Codable {
    let name: String
}

struct Post: Codable, Hashable {
    let id: Int
    let content: String
    let mood: String?
    let entry_date: String
    let created_at: String
    let user_id: UUID
    let ai_generated: Bool?
    
    var plainContent: String {
        if #available(iOS 15.0, *) {
            return content.htmlToPlainText()
        } else {
            return content.removingHTMLTags()
        }
    }
    
    var contentPreview: String {
        return content.toPreview(maxLength: 100)
    }
}

// MARK: - Hashtag Response Models

struct HashtagResponse: Codable {
    let id: Int
    let name: String
}

struct PostHashtagRelation: Codable {
    let post_id: Int
    let hashtag_id: Int
}

// MARK: - PostService

class PostService {
    private let supabase = SupabaseManager.shared.client
    
    private var currentUserId: UUID? {
        return SupabaseManager.shared.currentUser?.id
    }
    
    // MARK: - Read Operations
    
    /// 날짜 범위로 포스트 가져오기
    func fetchPostsForDateRange(from startDate: Date, to endDate: Date) async throws -> [Post] {
        guard let userId = currentUserId else {
            throw PostError.notAuthenticated
        }
        
        let startDateString = DateUtility.shared.dateString(from: startDate)
        let endDateString = DateUtility.shared.dateString(from: endDate)
        
        let posts: [Post] = try await supabase
            .from("Post")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("entry_date", value: startDateString)
            .lte("entry_date", value: endDateString)
            .order("entry_date", ascending: false)
            .execute()
            .value
        
        return posts
    }
    
    /// 특정 ID의 포스트 가져오기
    func fetchPost(id: Int) async throws -> Post {
        guard let userId = currentUserId else {
            throw PostError.notAuthenticated
        }
        
        let post: Post = try await supabase
            .from("Post")
            .select()
            .eq("id", value: id)
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        return post
    }
    
    /// 포스트 상세 정보 가져오기 (이미지 포함)
    func fetchPostDetail(id postId: Int) async throws -> PostDetail {
        guard let userId = currentUserId else {
            throw PostError.notAuthenticated
        }
        
        print("📖 포스트 상세 조회: ID \(postId)")
        
        let query = """
            id,
            content,
            mood,
            allow_ai_comments,
            ai_processing_status,
            ai_generated,
            entry_date,
            created_at,
            updated_at,
            user_id,
            Comment (
                id,
                character_id,
                message,
                created_at
            ),
            Post_Hashtag (
                hashtag_id,
                Hashtag (
                    name
                )
            ),
            Image (
                id,
                storage_path,
                display_order,
                file_size,
                created_at
            )
        """
        
        let postDetail: PostDetail = try await supabase
            .from("Post")
            .select(query)
            .eq("id", value: postId)
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        print("✅ 포스트 상세 가져옴 (댓글: \(postDetail.Comment?.count ?? 0)개, 이미지: \(postDetail.Image?.count ?? 0)개)")
        return postDetail
    }
    
    // MARK: - Write Operations
    
    /// 새 포스트 생성 (해시태그 지원)
    func createPost(
        content: String,
        mood: String?,
        hashtags: [String] = [],
        entryDate: Date? = nil,
        characterId: Int? = nil,
        allowAIComments: Bool = true,
        aiGenerated: Bool = false
    ) async throws -> Post {
        guard let userId = currentUserId else {
            throw PostError.notAuthenticated
        }
        
        struct NewPost: Codable {
            let content: String
            let mood: String?
            let entry_date: String
            let user_id: String
            let character_id: Int?
            let allow_ai_comments: Bool
            let ai_processing_status: String
            let ai_generated: Bool
        }
        
        let date = entryDate ?? Date()
        let newPost = NewPost(
            content: content,
            mood: mood,
            entry_date: DateUtility.shared.dateString(from: date),
            user_id: userId.uuidString,
            character_id: characterId,
            allow_ai_comments: allowAIComments,
            ai_processing_status: allowAIComments ? "pending" : "completed",
            ai_generated: aiGenerated
        )
        
        // 1. Post 생성
        let createdPost: Post = try await supabase
            .from("Post")
            .insert(newPost)
            .select()
            .single()
            .execute()
            .value
        
        // 2. 해시태그 처리
        if !hashtags.isEmpty {
            let hashtagIds = try await createOrGetHashtags(hashtags)
            try await attachHashtagsToPost(postId: createdPost.id, hashtagIds: hashtagIds)
        }
        
        print("✅ 포스트 생성 완료 (ID: \(createdPost.id), 해시태그: \(hashtags.count)개)")
        return createdPost
    }
    
    /// 포스트 업데이트
    // PostService.swift

    /// Post 업데이트 (content, mood, hashtags)
    func updatePost(
        id: Int,
        content: String?,
        mood: String?,
        hashtags: [String]?
    ) async throws -> Post {
        guard let userId = currentUserId else {
            throw PostError.notAuthenticated
        }
        
        // 1. Post 기본 정보 업데이트
        let updatedPost: Post
        if content != nil || mood != nil {
            struct UpdateData: Codable {
                let content: String?
                let mood: String?
            }
            
            updatedPost = try await supabase
                .from("Post")
                .update(UpdateData(content: content, mood: mood))
                .eq("id", value: id)
                .eq("user_id", value: userId.uuidString)
                .select()
                .single()
                .execute()
                .value
        } else {
            updatedPost = try await fetchPost(id: id)
        }
        
        // 2. 해시태그 업데이트
        if let newHashtags = hashtags {
            // 기존 관계 삭제
            try await supabase
                .from("Post_Hashtag")
                .delete()
                .eq("post_id", value: id)
                .execute()
            
            // 새 관계 생성
            if !newHashtags.isEmpty {
                let hashtagIds = try await createOrGetHashtags(newHashtags)
                try await attachHashtagsToPost(postId: id, hashtagIds: hashtagIds)
            }
            
            print("✅ Updated hashtags: \(newHashtags.count) tags")
        }
        
        return updatedPost
    }
    
    /// 포스트 삭제
    func deletePost(id: Int) async throws {
        guard let userId = currentUserId else {
            throw PostError.notAuthenticated
        }
        
        try await supabase
            .from("Post")
            .delete()
            .eq("id", value: id)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        print("✅ 포스트 삭제 완료 (ID: \(id))")
    }

    /// 댓글 삭제
    func deleteComment(id: Int) async throws {
        try await supabase
            .from("Comment")
            .delete()
            .eq("id", value: id)
            .execute()

        print("✅ 댓글 삭제 완료 (ID: \(id))")
    }

    // MARK: - Hashtag Operations (Private)
    
    /// 해시태그 생성 또는 기존 ID 가져오기
    private func createOrGetHashtags(_ names: [String]) async throws -> [Int] {
        var ids: [Int] = []
        
        for name in names {
            let cleanName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !cleanName.isEmpty else { continue }
            
            // 기존 해시태그 확인
            let existingResponse = try? await supabase
                .from("Hashtag")
                .select("id")
                .eq("name", value: cleanName)
                .execute()
            
            if let data = existingResponse?.data,
               let existing = try? JSONDecoder().decode([HashtagResponse].self, from: data).first {
                ids.append(existing.id)
                print("📌 기존 해시태그 사용: \(cleanName) (ID: \(existing.id))")
            } else {
                // 새 해시태그 생성
                struct NewHashtag: Codable {
                    let name: String
                }
                
                let created: HashtagResponse = try await supabase
                    .from("Hashtag")
                    .insert(NewHashtag(name: cleanName))
                    .select()
                    .single()
                    .execute()
                    .value
                
                ids.append(created.id)
                print("📌 새 해시태그 생성: \(cleanName) (ID: \(created.id))")
            }
        }
        
        return ids
    }
    
    /// Post와 해시태그 연결
    private func attachHashtagsToPost(postId: Int, hashtagIds: [Int]) async throws {
        let relations = hashtagIds.map {
            PostHashtagRelation(post_id: postId, hashtag_id: $0)
        }
        
        guard !relations.isEmpty else { return }
        
        try await supabase
            .from("Post_Hashtag")
            .insert(relations)
            .execute()
        
        print("🔗 Post-Hashtag 연결 완료: \(relations.count)개")
    }
    
    // MARK: - Statistics
    
    /// 전체 포스트 개수 가져오기
    func fetchTotalPostCount() async throws -> Int {
        guard let userId = currentUserId else {
            throw PostError.notAuthenticated
        }
        
        let response = try await supabase
            .from("Post")
            .select("*", head: true, count: .exact)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        return response.count ?? 0
    }
}

// MARK: - PostImageInfo Extension

extension PostImageInfo {
    var publicURL: String {
        return (try? ImageService.shared.getPublicURL(for: storagePath)) ?? ""
    }
}

// MARK: - Post Errors

enum PostError: LocalizedError {
    case notAuthenticated
    case noUpdateContent
    case networkError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "로그인이 필요합니다"
        case .noUpdateContent:
            return "업데이트할 내용이 없습니다"
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
}
