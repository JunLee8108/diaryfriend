//
//  PostDiary.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/29/25.
//

import SwiftUI

// MARK: - Diary Text Section

struct DiaryTextSection: View {
    @Binding var diaryText: String
    @FocusState var isTextEditorFocused: Bool
    
    @Localized(.diary_section_title) var sectionTitle
    @Localized(.diary_placeholder) var placeholder
    @Localized(.common_done) var doneText
    
    private let maxCharacters = 1000
    
    private var characterCount: Int {
        diaryText.count
    }
    
    private var characterCountColor: Color {
        if characterCount > 900 {
            return Color(hex: "FF6B6B")
        } else if characterCount > 750 {
            return Color(hex: "FFB6A3")
        } else {
            return .secondary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(sectionTitle)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
            
            ZStack(alignment: .topLeading) {
                // Background with rounded corners
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.modernSurfacePrimary)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                
                // Content
                VStack {
                    ZStack(alignment: .topLeading) {
                        // Placeholder
                        if diaryText.isEmpty {
                            Text(placeholder)
                                .font(.system(size: 15, design: .rounded))
                                .lineSpacing(8)
                                .foregroundColor(.secondary.opacity(0.4))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                        
                        // TextEditor with transparent background
                        TextEditor(text: $diaryText)
                            .font(.system(size: 16, design: .rounded))
                            .lineSpacing(8)
                            .foregroundColor(.primary)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .focused($isTextEditorFocused)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button(doneText) {
                                        isTextEditorFocused = false
                                    }
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                            }
                            .onChange(of: diaryText) { oldValue, newValue in
                                if newValue.count > maxCharacters {
                                    diaryText = String(newValue.prefix(maxCharacters))
                                }
                            }
                    }
                    
                    Spacer()
                }
                
                // Character counter
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(characterCount)/\(maxCharacters)")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(characterCountColor)
                            .padding(10)
                    }
                }
            }
            .frame(height: 250)
            .padding(.horizontal, 24)
        }
    }
}
