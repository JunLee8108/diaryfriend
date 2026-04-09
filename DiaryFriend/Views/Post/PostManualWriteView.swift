// Views/Post/PostManualWriteView.swift

import SwiftUI

struct PostManualWriteView: View {
    @StateObject private var creationManager = PostCreationManager.shared
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var characterStore = CharacterStore.shared
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss
    
    // State
    @State private var selectedMood: Mood = .neutral
    @State private var hashtags: [String] = []
    @State private var diaryText: String = ""
    @State private var isAICommentEnabled: Bool = false
    @State private var selectedImages: [UIImage] = []
    
    // UI State
    @State private var tempHashtagInput: String = ""
    @State private var showingHashtagSheet: Bool = false
    @State private var showingDiscardAlert: Bool = false
    @State private var isSaving: Bool = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCharacterSelection = false
    @FocusState private var isTextEditorFocused: Bool
    
    @Localized(.common_save) var saveText
    
    // Computed Properties
    private var hasFollowingCharacters: Bool {
        !characterStore.followingCharacters.isEmpty
    }
    
    // Date formatting
    private var dateTitle: String {
        guard let date = creationManager.selectedDate else { return "Today" }
        return DateUtility.shared.monthDay(from: date)
    }
    
    // Validation
    private var isValid: Bool {
        diaryText.count >= 5 && diaryText.count <= 1000
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.modernBackground
                .ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom) {
            // Main Content
            ScrollView {
                VStack(spacing: 28) {
                    // Header Section
                    HeaderSection(dateTitle: dateTitle)
                    
                    // Text Editor
                    DiaryTextSection(
                        diaryText: $diaryText,
                        isTextEditorFocused: _isTextEditorFocused
                    )
                    
                    // Mood Selection
                    MoodSelectionSection(selectedMood: $selectedMood)
                    
                    // Hashtag Input
                    HashtagSection(
                        hashtags: $hashtags,
                        showingSheet: $showingHashtagSheet,
                        tempInput: $tempHashtagInput
                    )
                    
                    ImageAttachmentSection(
                        selectedImages: $selectedImages,
                    )
                    
                    // AI Comment Toggle
                    if hasFollowingCharacters {
                        AICommentToggleSection(isEnabled: $isAICommentEnabled)
                    } else {
                        NoFollowingCharactersSection(
                            onNavigateToProfile: {
                                showCharacterSelection = true
                            }
                        )
                    }
                    
                    // Inline Save Button
                    InlineSaveButton(
                        isValid: isValid,
                        isSaving: isSaving,
                        action: saveEntry
                    )
                }
            }
            .onTapGesture {
                // Hide keyboard when tapping outside
                hideKeyboard()
            }
            .safeAreaPadding(.bottom, 50)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: saveEntry) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Text(saveText)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(isValid ? Color(hex: "E8826B") : Color.gray)
                    }
                }
                .disabled(!isValid || isSaving)
            }
        }
        .alert("Discard Entry?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Writing", role: .cancel) {}
        } message: {
            Text("Your entry will be lost if you leave now.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingHashtagSheet) {
            AddHashtagSheet(
                tempInput: $tempHashtagInput,
                hashtags: $hashtags,
                isPresented: $showingHashtagSheet
            )
        }
        .sheet(isPresented: $showCharacterSelection) {
            CharacterSelectionView(isPresented: $showCharacterSelection)
            
                .onDisappear {
                    // Sheet가 닫힐 때 팔로우한 캐릭터가 있으면 AI 토글 자동 활성화
                    if hasFollowingCharacters && !isAICommentEnabled {
                        isAICommentEnabled = true
                    }
                }
        }
        .onAppear {
            Task {
                // 캐릭터 데이터가 없으면 로드
                if characterStore.allCharacters.isEmpty {
                    await characterStore.loadAllCharacters()
                }
                
                // 팔로우 중인 캐릭터가 있으면 AI 코멘트 기본 활성화
                if hasFollowingCharacters {
                    isAICommentEnabled = true
                }
            }
        }
        .onChange(of: hasFollowingCharacters) { _, newValue in
            // 팔로우 중인 캐릭터가 없어지면 자동으로 비활성화
            if !newValue {
                isAICommentEnabled = false
            }
        }
    }
    
    private func saveEntry() {
        guard isValid else { return }
        guard !isSaving else { return }  // 중복 실행 방지
        
        Task {
            isSaving = true
            
            do {
                // 날짜 검증
                guard let entryDate = creationManager.selectedDate else {
                    throw NSError(
                        domain: "PostManualWriteView",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid date. Please select a date."]
                    )
                }
                
                // 1. 이미지 업로드
                var uploadedImageInfo: [(path: String, size: Int)] = []
                
                if !selectedImages.isEmpty {
                    for (index, image) in selectedImages.enumerated() {
                        let path = try await ImageService.shared.uploadImage(image, order: index)
                        let size = image.jpegData(compressionQuality: 0.8)?.count ?? 0
                        uploadedImageInfo.append((path: path, size: size))
                        print("🔸 Uploaded image \(index + 1)/\(selectedImages.count)")
                    }
                }
                
                // 2. Post 생성
                let newPost = try await DataStore.shared.createPost(
                    content: diaryText,
                    mood: selectedMood.rawValue,
                    hashtags: hashtags,
                    entryDate: entryDate,
                    allowAIComments: isAICommentEnabled,
                    images: uploadedImageInfo,
                    aiGenerated: false
                )
                
                // 3. 성공 처리 - Navigation
                await MainActor.run {
                    // 햅틱 피드백
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    
                    // Manager 정리
                    PostCreationManager.shared.clearAll()
                    
                    // 이미지 배열 클리어
                    selectedImages.removeAll()
                    
                    // ✅ PostDetailView로 이동
                    navigationCoordinator.navigateToPostDetail(newPost.id)
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PostManualWriteView()
    }
}
