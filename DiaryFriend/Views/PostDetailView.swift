import SwiftUI

struct PostDetailView: View {
    let postId: Int
    private let dataStore = DataStore.shared
    private let characterStore = CharacterStore.shared
    
    @State private var postDetail: PostDetail?
    @State private var enrichedComments: [EnrichedComment] = []
    @State private var isInitialLoad = true
    @State private var isLoading = true
    @State private var isWaitingForAI = false
    
    @State private var showEditView = false
    
    @State private var showDeleteConfirmation = false
    @State private var deleteError: String?
    @State private var showDeleteError = false
    
    @Environment(\.dismiss) private var dismiss
    
    @Localized(.post_detail_delete_title) var deleteTitle: String
    @Localized(.post_detail_delete_message) var deleteMessage: String
    @Localized(.common_cancel) var cancelText
    @Localized(.common_delete) var deleteText
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tint(.primary)
            } else if let detail = postDetail {
                PostContentView(
                    detail: detail,
                    enrichedComments: enrichedComments,
                    isWaitingForAI: isWaitingForAI
                )
            } else {
                Text("포스트를 불러올 수 없습니다")
                    .foregroundColor(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task {
            if characterStore.allCharacters.isEmpty {
                await characterStore.loadAllCharacters()
            }
            await loadPost()
            isInitialLoad = false
        }
        .onReceive(dataStore.$updatedPostDetailId) { updatedId in
            guard updatedId == postId else { return }
            guard !isInitialLoad else { return }  // ✅ 초기 로드 중이면 무시
            
            Task {
                await reloadPostDetail()
            }
        }
        .background(Color.modernBackground)
        .confirmationModal(
            isPresented: $showDeleteConfirmation,
            title: deleteTitle,
            message: deleteMessage,
            icon: "trash",
            confirmText: deleteText,
            cancelText: cancelText,
            isDestructive: true,
            onConfirm: {
                await performDelete()
            }
        )
        .alert("Delete Failed", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteError ?? "Failed to delete the post. Please try again.")
        }
        .sheet(isPresented: $showEditView) {
            if let detail = postDetail {
                NavigationStack {
                    PostEditView(postDetail: detail)
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        @Localized(.common_edit) var editText
        @Localized(.common_delete) var deleteText
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(editText, systemImage: "pencil") {
                    showEditView = true
                }
                Button(deleteText, systemImage: "trash", role: .destructive) {
                    showDeleteConfirmation = true
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .tint(nil)
        }
    }
    
    private func loadPost() async {
        if characterStore.allCharacters.isEmpty {
            await characterStore.loadAllCharacters()
        }
        
        if let detail = await dataStore.getPostDetail(id: postId) {
            self.postDetail = detail
            
            // pending 상태 체크
            isWaitingForAI = (detail.ai_processing_status == "pending")
            
            if let comments = detail.Comment {
                self.enrichedComments = await enrichComments(comments)
            }
        }
        
        isLoading = false
    }
    
    private func reloadPostDetail() async {
        guard let detail = await dataStore.getPostDetail(id: postId) else {
            return
        }
        
        self.postDetail = detail
        isWaitingForAI = (detail.ai_processing_status == "pending")
        
        if let comments = detail.Comment {
            self.enrichedComments = await enrichComments(comments)
        }
        
        // 댓글 도착 시 햅틱 피드백
        if !enrichedComments.isEmpty && !isWaitingForAI {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func performDelete() async {
        do {
            let postDate = postDetail.flatMap {
                DateUtility.shared.date(from: $0.entry_date)
            } ?? Date()
            
            let isAIGenerated = postDetail?.ai_generated ?? false
            
            try await dataStore.deletePost(
                id: postId,
                date: postDate,
                aiGenerated: isAIGenerated  // ✅ 전달
            )
            dismiss()
        } catch {
            deleteError = error.localizedDescription
            showDeleteError = true
        }
    }
    
    private func enrichComments(_ comments: [Comment]) async -> [EnrichedComment] {
        var enriched: [EnrichedComment] = []
        let characterIds = Array(Set(comments.map { $0.character_id }))
        let characters = await characterStore.getCharacters(ids: characterIds)
        
        for comment in comments {
            if let character = characters[comment.character_id] {
                enriched.append(EnrichedComment(
                    comment: comment,
                    character: character
                ))
            }
        }
        
        return enriched
    }
}

// MARK: - Enriched Comment Model
struct EnrichedComment: Identifiable {
    let comment: Comment
    let character: CharacterWithAffinity
    
    var id: Int { comment.id }
    
    func localizedName(isKorean: Bool) -> String {
        character.localizedName(isKorean: isKorean)
    }
    
    var avatarUrl: String? {
        character.avatar_url
    }
    
    var avatarInitial: String {
        String(character.name.first ?? "?")
    }
    
    var affinity: Int {
        character.affinity
    }
}

// MARK: - Content View
struct PostContentView: View {
    let detail: PostDetail
    let enrichedComments: [EnrichedComment]
    let isWaitingForAI: Bool
    
    @State private var selectedCharacter: CharacterWithAffinity?
    
    private var dayNumber: String {
        DateUtility.shared.dayNumber(from: detail.entry_date)
    }
    
    private var monthYear: String {
        DateUtility.shared.monthYear(from: detail.entry_date)
    }
    
    private var weekday: String {
        DateUtility.shared.weekdayFull(from: detail.entry_date)
    }
    
    private var moodIcon: String? {
        guard let mood = detail.mood else { return nil }
        return MoodMapper.shared.icon(for: mood)
    }
    
    private var moodColor: Color? {
        guard let mood = detail.mood else { return nil }
        return MoodMapper.shared.color(for: mood)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // 날짜 헤더
                HStack(alignment: .center, spacing: 20) {
                    Text(dayNumber)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(monthYear)
                            .font(.system(size: 18, weight: .medium))
                        
                        HStack(spacing: 6) {
                            Text(weekday)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            if let icon = moodIcon, let color = moodColor {
                                Image(systemName: icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(color)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // 본문
                Text(detail.plainContent)
                    .font(.system(size: 16))
                    .lineSpacing(8)
                
                // 이미지 섹션
                if let images = detail.Image, !images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(images.sorted { $0.displayOrder < $1.displayOrder }, id: \.id) { imageInfo in
                                PostDetailImageCard(imageInfo: imageInfo)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, -20)
                }
                
                // 해시태그
                if !detail.hashtags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(detail.hashtags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Color.gray.opacity(0.1)
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Divider()
                
                // 댓글
                if isWaitingForAI {
                    AIProcessingView()
                        .padding(.vertical, 20)
                } else if enrichedComments.isEmpty {
                    EmptyCommentsView()
                        .padding(.vertical, 20)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(enrichedComments) { enrichedComment in
                            CommentRowView(
                                enrichedComment: enrichedComment,
                                onCharacterTap: {
                                    selectedCharacter = enrichedComment.character
                                }
                            )
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.3), value: enrichedComments.count)
                }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 20)
        }
        .sheet(item: $selectedCharacter) { character in
            CharacterDetailSheet(
                character: character,
                onFollowToggle: {
                    await CharacterStore.shared.toggleFollowing(characterId: character.id)
                    if let updated = CharacterStore.shared.allCharacters.first(where: { $0.id == character.id }) {
                        selectedCharacter = updated
                    }
                }
            )
        }
    }
}

// MARK: - Post Detail Image Card
struct PostDetailImageCard: View {
    let imageInfo: PostImageInfo
    @State private var selectedImageURL: String?
    
    var body: some View {
        CachedThumbnailImage(
            url: imageInfo.publicURL,
            width: 120,
            height: 120,
            cornerRadius: 16
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .onTapGesture {
            selectedImageURL = imageInfo.publicURL
        }
        .sheet(item: Binding(
            get: { selectedImageURL.map { IdentifiableString(value: $0) } },
            set: { selectedImageURL = $0?.value }
        )) { wrapper in
            StorageImageViewerModal(url: wrapper.value)
        }
    }
}

// MARK: - Helper
struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

// MARK: - Comment Row
struct CommentRowView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let enrichedComment: EnrichedComment
    let onCharacterTap: () -> Void
    
    // ✅ 언어 체크
    private var isKorean: Bool {
        localizationManager.currentLanguage == .korean
    }
    
    // ✅ 다국어 이름
    private var displayName: String {
        enrichedComment.localizedName(isKorean: isKorean)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onCharacterTap) {
                CachedAvatarImage(
                    url: enrichedComment.avatarUrl,
                    size: 40,
                    initial: enrichedComment.avatarInitial
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                
                Text(enrichedComment.comment.message)
                    .font(.system(size: 14))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineSpacing(4)
            }
            
            Spacer()
        }
    }
}

// MARK: - AI Processing View
struct AIProcessingView: View {
    @Localized(.post_detail_processing) var postDetailProcessing: String
    @Localized(.post_detail_wait) var postDetailWait: String
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.secondary)
            
            Text(postDetailProcessing)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Text(postDetailWait)
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// MARK: - Empty Comments View
struct EmptyCommentsView: View {
    @Localized(.post_detail_empty) var postDetailEmpty: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(postDetailEmpty)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
