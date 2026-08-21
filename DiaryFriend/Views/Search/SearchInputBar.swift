//
//  SearchInputBar.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/9/25.
//
//  공용 검색 필드 스펙 (프로필/Find Characters와 동일):
//  systemGray6 라운드 12 + 그린 포커스 링 + 고정 높이 + X 지우기 버튼.
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
        HStack(spacing: 8) {
            // Search Icon — 입력이 있으면 브랜드 그린
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(text.isEmpty ? .secondary : Color(hex: "00C896"))
                .animation(.easeInOut(duration: 0.2), value: text.isEmpty)

            TextField(placeholder, text: $text)
                .font(.system(size: 14, design: .rounded))
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
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.pressable)
                .transition(.scale.combined(with: .opacity))
            }
        }
        // 높이 고정 — 포커스 시 TextField 고유 높이 변화로 필드가 줄어드는 것 방지
        .frame(height: 24)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        // 포커스 링 — 애니메이션은 링에만 국한
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    Color(hex: "00C896").opacity(isFocused ? 0.35 : 0),
                    lineWidth: 1
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused)
        )
        .contentShape(Rectangle())  // HStack 전체 영역을 탭 가능하게 만듦
        .onTapGesture {
            isFocused = true  // 어디를 눌러도 포커스
        }
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: isSearching)
    }
}
