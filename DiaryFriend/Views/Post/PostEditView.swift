//
//  PostEditView.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/3/25.
//
// Views/Post/PostEditView.swift

import SwiftUI

struct PostEditView: View {
    let postDetail: PostDetail
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataStore = DataStore.shared
    
    // 편집 상태
    @State private var editedContent: String
    @State private var editedMood: Mood
    @State private var editedHashtags: [String]
    @State private var existingImages: [PostImageInfo]
    @State private var newImages: [UIImage] = []
    @State private var imagesToDelete: Set<String> = []
    
    // UI 상태
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDiscardAlert = false
    @State private var tempHashtagInput = ""
    @State private var showHashtagSheet = false
    @FocusState private var isTextEditorFocused: Bool
    
    @Localized(.common_cancel) var cancelText
    @Localized(.common_save) var saveText
    
    init(postDetail: PostDetail) {
        self.postDetail = postDetail
        _editedContent = State(initialValue: postDetail.plainContent)
        _editedMood = State(initialValue: Mood(rawValue: postDetail.mood ?? "neutral") ?? .neutral)
        _editedHashtags = State(initialValue: postDetail.hashtags)
        _existingImages = State(initialValue: postDetail.Image ?? [])
    }
    
    private var hasChanges: Bool {
        let contentChanged = editedContent != postDetail.plainContent
        let moodChanged = editedMood.rawValue != postDetail.mood
        let hashtagsChanged = Set(editedHashtags) != Set(postDetail.hashtags)
        let imagesChanged = !imagesToDelete.isEmpty || !newImages.isEmpty
        
        return contentChanged || moodChanged || hashtagsChanged || imagesChanged
    }
    
    private var isValid: Bool {
        editedContent.count >= 10 && editedContent.count <= 1000
    }
    
    private var dateTitle: String {
        guard let date = DateUtility.shared.date(from: postDetail.entry_date) else {
            return "Unknown Date"
        }
        return DateUtility.shared.monthDay(from: date)
    }
    
    var body: some View {
        ZStack {
            Color.modernBackground
                .ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom) {
            ScrollView {
                VStack(spacing: 34) {
                    HeaderSection(dateTitle: dateTitle)
                        .padding(.top, 30)
                        .padding(.bottom, 20)
                    
                    DiaryTextSection(
                        diaryText: $editedContent,
                        isTextEditorFocused: _isTextEditorFocused
                    )
                    
                    MoodSelectionSection(selectedMood: $editedMood)
                    
                    HashtagSection(
                        hashtags: $editedHashtags,
                        showingSheet: $showHashtagSheet,
                        tempInput: $tempHashtagInput
                    )
                    
                    ImageEditSection(
                        existingImages: $existingImages,
                        newImages: $newImages,
                        imagesToDelete: $imagesToDelete,
                        maxImages: 3
                    )
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .safeAreaPadding(.bottom, 50)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(cancelText) {
                    if hasChanges {
                        showDiscardAlert = true
                    } else {
                        dismiss()
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: saveChanges) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Text(saveText)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(isValid && hasChanges ? Color(hex: "FFB6A3") : Color.gray)
                    }
                }
                .disabled(!isValid || !hasChanges || isSaving)
            }
        }
        .alert("Discard Changes?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Your changes will be lost if you leave now.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showHashtagSheet) {
            AddHashtagSheet(
                tempInput: $tempHashtagInput,
                hashtags: $editedHashtags,
                isPresented: $showHashtagSheet
            )
        }
    }
    
    private func saveChanges() {
        guard isValid && hasChanges else { return }
        
        Task {
            isSaving = true
            
            do {
                try await dataStore.updatePost(
                    id: postDetail.id,
                    content: editedContent != postDetail.plainContent ? editedContent : nil,
                    mood: editedMood.rawValue != postDetail.mood ? editedMood.rawValue : nil,
                    hashtags: Set(editedHashtags) != Set(postDetail.hashtags) ? editedHashtags : nil,
                    newImages: newImages.isEmpty ? nil : newImages,
                    imagesToDelete: imagesToDelete.isEmpty ? nil : Array(imagesToDelete)
                )
                
                await MainActor.run {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    dismiss()
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
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
