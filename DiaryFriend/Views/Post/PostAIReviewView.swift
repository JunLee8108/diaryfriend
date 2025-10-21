//
//  PostAIReviewView.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/30/25.
//

// Views/Post/PostAIReviewView.swift
import SwiftUI

struct PostAIReviewView: View {
    // Parameters
    let characterId: Int
    let selectedDate: Date
    let sessionId: UUID
    let generatedContent: String
    let aiMood: String
    let aiHashtags: [String]
    
    // Managers
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var chatService = ChatService.shared
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss
    
    // State
    @State private var editedContent: String
    @State private var selectedMood: Mood
    @State private var customHashtags: [String]
    @State private var isAICommentEnabled = true
    @State private var selectedImages: [UIImage] = []
    
    // UI State
    @State private var tempHashtagInput = ""
    @State private var showingHashtagSheet = false
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isTextEditorFocused: Bool
    
    // Date formatting
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: selectedDate)
    }
    
    // Validation
    private var isValid: Bool {
        editedContent.count >= 10 && editedContent.count <= 1000
    }
    
    init(characterId: Int, selectedDate: Date, sessionId: UUID,
         generatedContent: String, aiMood: String, aiHashtags: [String]) {
        self.characterId = characterId
        self.selectedDate = selectedDate
        self.sessionId = sessionId
        self.generatedContent = generatedContent
        self.aiMood = aiMood
        self.aiHashtags = aiHashtags
        
        // HTML to plain text conversion
        let plainText = generatedContent
            .replacingOccurrences(of: "<p>", with: "\n")
            .replacingOccurrences(of: "</p>", with: "")
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        _editedContent = State(initialValue: plainText)
        _selectedMood = State(initialValue: Mood(rawValue: aiMood) ?? .neutral)
        
        let cleanedHashtags = aiHashtags.map { hashtag in
            hashtag.trimmingCharacters(in: .whitespacesAndNewlines)
                   .replacingOccurrences(of: "#", with: "")
        }.filter { !$0.isEmpty }  // 빈 문자열 제거
        
        _customHashtags = State(initialValue: cleanedHashtags)
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
                VStack(spacing: 34) {
                    // AI Generated Label
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("AI Generated")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color(hex: "00A077"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: "00A077").opacity(0.1))
                    )
                    
                    // Header Section
                    HeaderSection(dateTitle: formattedDate)
                        
                    // Diary Text
                    DiaryTextSection(
                        diaryText: $editedContent,
                        isTextEditorFocused: _isTextEditorFocused
                    )
                    
                    // Mood Selection
                    MoodSelectionSection(selectedMood: $selectedMood)
                    
                    // Hashtag Input - with maxCount
                    HashtagSection(
                        hashtags: $customHashtags,
                        showingSheet: $showingHashtagSheet,
                        tempInput: $tempHashtagInput,
                        maxCount: 5
                    )
                    
                    // Image Attachment Section
                    ImageAttachmentSection(
                        selectedImages: $selectedImages
                    )
                    
                    // AI Comment Toggle
                    AICommentToggleSection(isEnabled: $isAICommentEnabled)
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .safeAreaPadding(.bottom, 50)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Review Diary")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                
                Button(action: saveDiary) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(isValid ? Color(hex: "00A077") : Color.gray)
                    }
                }
                .disabled(!isValid || isSaving)
            }
        }
        .sheet(isPresented: $showingHashtagSheet) {
            AddHashtagSheetForAI(
                tempInput: $tempHashtagInput,
                hashtags: $customHashtags,
                isPresented: $showingHashtagSheet,
                maxCount: 5
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveDiary() {
        guard !isSaving else { return }
        
        Task {
            isSaving = true
            
            do {
                // 1. 이미지 업로드
                var uploadedImageInfo: [(path: String, size: Int)] = []
                
                if !selectedImages.isEmpty {
                    for (index, image) in selectedImages.enumerated() {
                        let path = try await ImageService.shared.uploadImage(
                            image,
                            order: index
                        )
                        let size = image.jpegData(compressionQuality: 0.8)?.count ?? 0
                        uploadedImageInfo.append((path: path, size: size))
                        print("📸 Uploaded image \(index + 1)/\(selectedImages.count)")
                    }
                }
                
                // 2. Post 생성
                let newPost = try await DataStore.shared.createPost(
                    content: editedContent,
                    mood: selectedMood.rawValue,
                    hashtags: customHashtags,
                    entryDate: selectedDate,
                    characterId: characterId,
                    allowAIComments: isAICommentEnabled,
                    images: uploadedImageInfo,
                    aiGenerated: true
                )
                
                // 3. ChatService 세션 잠금
                try await ChatService.shared.lockDailyAccess(
                    date: selectedDate,
                    postId: newPost.id,
                    sessionId: sessionId
                )
                
                // ✅ 4. 저장 성공 → 캐시된 생성 데이터 삭제
                ChatService.shared.clearGeneratedDiary(sessionId: sessionId)
                
                // 5. 성공 처리 - Navigation
                await MainActor.run {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    PostCreationManager.shared.clearAll()
                    selectedImages.removeAll()
                    navigationCoordinator.navigateToPostDetail(newPost.id)
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Modified AddHashtagSheet for AI
struct AddHashtagSheetForAI: View {
    @Binding var tempInput: String
    @Binding var hashtags: [String]
    @Binding var isPresented: Bool
    let maxCount: Int
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add a tag")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("#")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        TextField("Enter tag", text: $tempInput)
                            .font(.system(size: 16, design: .rounded))
                            .focused($isInputFocused)
                            .onSubmit {
                                addTag()
                            }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .padding(.horizontal)
                .padding(.top, 24)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(size: 16, design: .rounded))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addTag()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .disabled(tempInput.isEmpty)
                }
            }
            .onAppear {
                isInputFocused = true
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = tempInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !hashtags.contains(trimmedTag) && hashtags.count < maxCount {
            withAnimation {
                hashtags.append(trimmedTag)
            }
            isPresented = false
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PostAIReviewView(
            characterId: 1,
            selectedDate: Date(),
            sessionId: UUID(),
            generatedContent: "<p>Today was a wonderful day!</p>",
            aiMood: "happy",
            aiHashtags: ["daily", "mood"]
        )
    }
}
