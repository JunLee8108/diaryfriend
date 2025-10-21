//
//  PostHashtag.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/29/25.
//

// Views/Post/Components/PostHashtag.swift

import SwiftUI

// MARK: - Hashtag Section

struct HashtagSection: View {
    @Binding var hashtags: [String]
    @Binding var showingSheet: Bool
    @Binding var tempInput: String
    var maxCount: Int = 3  // 파라미터 추가
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tag")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(hashtags.count)/3")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(hashtags, id: \.self) { tag in
                        TagChip(
                            text: tag,
                            onDelete: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    hashtags.removeAll { $0 == tag }
                                }
                            }
                        )
                    }
                    
                    if hashtags.count < 3 {
                        AddTagButton {
                            tempInput = ""
                            showingSheet = true
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text("#\(text)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "FF6B6B"))
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "FF6B6B").opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(hex: "FFB6A3").opacity(0.15))
        )
    }
}

// MARK: - Add Tag Button

struct AddTagButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                Text("Add tag")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundColor(Color(hex: "FFB6A3"))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .stroke(Color(hex: "FFB6A3").opacity(0.3), lineWidth: 1.5)
                    .background(
                        Capsule()
                            .fill(Color(hex: "FFB6A3").opacity(0.05))
                    )
            )
        }
    }
}

// MARK: - Add Hashtag Sheet

struct AddHashtagSheet: View {
    @Binding var tempInput: String
    @Binding var hashtags: [String]
    @Binding var isPresented: Bool
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
        if !trimmedTag.isEmpty && !hashtags.contains(trimmedTag) && hashtags.count < 3 {
            withAnimation {
                hashtags.append(trimmedTag)
            }
            isPresented = false
        }
    }
}
