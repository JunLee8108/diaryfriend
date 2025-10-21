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
    
    private var buttonText: String {
        if isSaving {
            return "Saving..."
        } else if !isValid {
            return "Complete your entry"
        } else {
            return "Save Entry"
        }
    }
    
    private var buttonColor: Color {
        isValid ? Color(hex: "E8826B") : Color.modernSurfacePrimary.opacity(0.8)
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
        .accessibilityLabel(isValid ? "Save your diary entry" : "Complete your entry to save")
        .accessibilityHint(isValid ? "Tap to save your diary entry" : "Fill in at least 10 characters to enable saving")
    }
}

// MARK: - Preview

#Preview("Valid State") {
    VStack {
        Spacer()
        InlineSaveButton(
            isValid: true,
            isSaving: false,
            action: {}
        )
        .padding(.bottom, 34)
    }
    .background(Color.modernBackground)
}

#Preview("Invalid State") {
    VStack {
        Spacer()
        InlineSaveButton(
            isValid: false,
            isSaving: false,
            action: {}
        )
        .padding(.bottom, 34)
    }
    .background(Color.modernBackground)
}

#Preview("Saving State") {
    VStack {
        Spacer()
        InlineSaveButton(
            isValid: true,
            isSaving: true,
            action: {}
        )
        .padding(.bottom, 34)
    }
    .background(Color.modernBackground)
}
