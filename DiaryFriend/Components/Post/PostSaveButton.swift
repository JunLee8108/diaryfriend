//
//  PostSaveButton.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/6/25.
//

// Views/Post/Components/PostSaveButton.swift

import SwiftUI

// MARK: - Inline Save Button

struct InlineSaveButton: View {
    let isValid: Bool
    let isSaving: Bool
    let action: () -> Void
    
    // ⭐ LocalizationManager 직접 참조로 실시간 업데이트
    private var buttonText: String {
        if isSaving {
            return LocalizationManager.shared.localized(.post_saving)
        } else if !isValid {
            return LocalizationManager.shared.localized(.post_complete_entry)
        } else {
            return LocalizationManager.shared.localized(.post_save_entry)
        }
    }
    
    private var buttonColor: Color {
        isValid ? Color(hex: "E8826B") : Color.modernSurfacePrimary.opacity(0.8)
    }
    
    // ⭐ 접근성 레이블
    private var accessibilityLabelText: String {
        isValid
        ? LocalizationManager.shared.localized(.post_accessibility_save_label)
        : LocalizationManager.shared.localized(.post_accessibility_complete_label)
    }
    
    // ⭐ 접근성 힌트
    private var accessibilityHintText: String {
        isValid
        ? LocalizationManager.shared.localized(.post_accessibility_save_hint)
        : LocalizationManager.shared.localized(.post_accessibility_complete_hint)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                
                Text(buttonText)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isValid ? .white : Color.gray.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(buttonColor)
            )
            .shadow(
                color: isValid ? buttonColor.opacity(0.25) : Color.clear,
                radius: 8,
                y: 3
            )
        }
        .disabled(!isValid || isSaving)
        .padding(.horizontal, 24)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
    }
}
