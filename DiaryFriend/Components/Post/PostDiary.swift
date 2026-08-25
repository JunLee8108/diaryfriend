//
//  PostDiary.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/29/25.
//

import SwiftUI

// MARK: - Diary Limits
/// 일기 본문 글자 수 제한. 에디터 표시와 각 화면의 isValid 검증이
/// 같은 값을 참조하도록 한 곳에서 관리한다.
enum DiaryLimits {
    static let minCharacters = 5
    static let maxCharacters = 1000
}

// MARK: - Diary Text Section

struct DiaryTextSection: View {
    @Binding var diaryText: String
    @FocusState var isTextEditorFocused: Bool

    @Localized(.diary_section_title) var sectionTitle
    @Localized(.diary_placeholder) var placeholder
    @Localized(.common_done) var doneText

    private let maxCharacters = DiaryLimits.maxCharacters

    private var characterCount: Int {
        diaryText.count
    }

    /// 썼는데 최소 글자에 못 미칠 때만 힌트 표시 (0자에서는 placeholder가 안내 역할)
    private var showsMinHint: Bool {
        characterCount > 0 && characterCount < DiaryLimits.minCharacters
    }

    private var minHintText: String {
        String(
            format: LocalizationManager.shared.localized(.diary_min_characters),
            DiaryLimits.minCharacters
        )
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
                
                // Character counter + 최소 글자 힌트
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Spacer()

                        if showsMinHint {
                            Text(minHintText)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "FFB6A3"))
                                .transition(.opacity)
                        }

                        Text("\(characterCount)/\(maxCharacters)")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(characterCountColor)
                            .monospacedDigit()
                    }
                    .padding(10)
                    .animation(.easeInOut(duration: 0.2), value: showsMinHint)
                }
            }
            .frame(height: 250)
            .padding(.horizontal, 24)
        }
    }
}
