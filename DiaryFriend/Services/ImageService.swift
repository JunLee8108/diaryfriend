//
//  ImageService.swift
//  DiaryFriend
//
//  Supabase Storage와 Image 테이블 통신
//

import Foundation
import UIKit
import Supabase

// MARK: - Models

struct PostImage: Codable {
    let id: String
    let postId: Int
    let userId: UUID
    let storagePath: String
    let fileSize: Int?
    let mimeType: String?
    let displayOrder: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case storagePath = "storage_path"
        case fileSize = "file_size"
        case mimeType = "mime_type"
        case displayOrder = "display_order"
        case createdAt = "created_at"
    }
}

// MARK: - ImageService

class ImageService {
    // ✅ 싱글톤 인스턴스
    static let shared = ImageService()
    
    // ✅ private init으로 외부 인스턴스 생성 방지
    private init() {}
    
    private let supabase = SupabaseManager.shared.client
    
    private var currentUserId: UUID? {
        return SupabaseManager.shared.currentUser?.id
    }
    
    // MARK: - Upload
    
    /// 이미지를 Storage에 업로드하고 경로 반환
    func uploadImage(_ image: UIImage, order: Int) async throws -> String {
        guard let userId = currentUserId else {
            throw ImageError.notAuthenticated
        }
        
        // JPEG 데이터로 변환 (이미 압축된 이미지)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageError.conversionFailed
        }
        
        // 파일명 생성: {userId}/{timestamp}-{order}.jpg
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let fileName = "\(userId.uuidString)/\(timestamp)-\(order).jpg"
        
        print("📤 Uploading image: \(fileName), size: \(imageData.count / 1024)KB")
        
        // Storage 업로드
        do {
            try await supabase.storage
                .from("post-images")
                .upload(
                    fileName,
                    data: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg",
                        upsert: false
                    )
                )
            
            print("✅ Image uploaded: \(fileName)")
            return fileName
            
        } catch {
            print("❌ Upload failed: \(error)")
            throw ImageError.uploadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Create
    
    /// Image 테이블에 레코드 생성
    func createImageRecord(
        postId: Int,
        storagePath: String,
        fileSize: Int,
        displayOrder: Int
    ) async throws -> PostImage {
        guard let userId = currentUserId else {
            throw ImageError.notAuthenticated
        }
        
        struct NewImage: Codable {
            let post_id: Int
            let user_id: String
            let storage_path: String
            let file_size: Int
            let mime_type: String
            let display_order: Int
        }
        
        let newImage = NewImage(
            post_id: postId,
            user_id: userId.uuidString,
            storage_path: storagePath,
            file_size: fileSize,
            mime_type: "image/jpeg",
            display_order: displayOrder
        )
        
        let createdImage: PostImage = try await supabase
            .from("Image")
            .insert(newImage)
            .select()
            .single()
            .execute()
            .value
        
        print("✅ Image record created: ID \(createdImage.id)")
        return createdImage
    }
    
    /// 여러 이미지 레코드 생성 (배치)
    func createImageRecords(
        postId: Int,
        storagePaths: [(path: String, size: Int)]
    ) async throws {
        for (index, item) in storagePaths.enumerated() {
            _ = try await createImageRecord(
                postId: postId,
                storagePath: item.path,
                fileSize: item.size,
                displayOrder: index
            )
        }
        
        print("✅ Created \(storagePaths.count) image records for Post \(postId)")
    }
    
    // MARK: - Read
    
    /// Post에 연결된 이미지들 조회
    func fetchImages(forPostId postId: Int) async throws -> [PostImage] {
        guard let userId = currentUserId else {
            throw ImageError.notAuthenticated
        }
        
        let images: [PostImage] = try await supabase
            .from("Image")
            .select()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId.uuidString)
            .order("display_order", ascending: true)
            .execute()
            .value
        
        return images
    }
    
    /// Storage에서 Public URL 생성
    func getPublicURL(for storagePath: String) throws -> String {
        let publicURL = try supabase.storage
            .from("post-images")
            .getPublicURL(path: storagePath)
        
        return publicURL.absoluteString
    }
    
    // MARK: - Delete
    
    /// 이미지 레코드 삭제 (Storage는 RPC로 자동 처리)
    func deleteImage(id: String) async throws {
        try await supabase
            .from("Image")
            .delete()
            .eq("id", value: id)
            .execute()
        
        print("✅ Deleted image record: \(id)")
    }

    /// 여러 이미지 일괄 삭제
    func deleteImages(ids: [String]) async throws {
        guard !ids.isEmpty else { return }
        
        for id in ids {
            try await deleteImage(id: id)
        }
        
        print("✅ Deleted \(ids.count) image records")
    }
}

// MARK: - Image Errors

enum ImageError: LocalizedError {
    case notAuthenticated
    case conversionFailed
    case uploadFailed(String)
    case unauthorized
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "로그인이 필요합니다"
        case .conversionFailed:
            return "이미지 변환에 실패했습니다"
        case .uploadFailed(let message):
            return "이미지 업로드 실패: \(message)"
        case .unauthorized:
            return "권한이 없습니다"
        case .notFound:
            return "이미지를 찾을 수 없습니다"
        }
    }
}
