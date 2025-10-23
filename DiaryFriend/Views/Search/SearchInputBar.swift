//
//  SearchInputBar.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/9/25.
//

import SwiftUI

struct SearchInputBar: View {
    @Binding var text: String
    let isSearching: Bool
    let onClear: () -> Void
    let onSearch: () -> Void
    
    @FocusState private var isFocused: Bool
    
    @Localized(.search_placeholder) var placeholder
    
    var body: some View {
        HStack(spacing: 12) {
            // Search Icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(text.isEmpty ? .secondary : Color(hex: "00C896"))
                .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
            
            // Text Field
            TextField(placeholder, text: $text)
                .font(.system(size: 16, design: .rounded))
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    onSearch()
                    isFocused = false
                }
            
            // Loading or Clear Button
            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
                    .transition(.scale.combined(with: .opacity))
            } else if !text.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.modernSurfacePrimary)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .contentShape(Rectangle())  // HStack 전체 영역을 탭 가능하게 만듦
        .onTapGesture {
            isFocused = true  // 어디를 눌러도 포커스
        }
        .animation(.easeInOut(duration: 0.2), value: text)
        .animation(.easeInOut(duration: 0.2), value: isSearching)
    }
}
