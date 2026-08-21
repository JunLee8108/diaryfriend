//
//  CharacterSelectionView.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/6/25.
//
//  캐릭터 탐색/팔로우 시트. 프로필과 동일한 통합 리스트(modern + classic) + 검색.
//

import SwiftUI

struct CharacterSelectionView: View {
    @StateObject private var characterStore = CharacterStore.shared
    @Binding var isPresented: Bool

    @State private var searchText = ""
    @State private var selectedCharacter: CharacterWithAffinity?
    @FocusState private var isSearchFocused: Bool

    @Localized(.ai_insights_find_characters) var findCharactersText
    @Localized(.common_done) var doneText
    @Localized(.profile_search_placeholder) var searchPlaceholderText
    @Localized(.profile_search_no_results) var searchNoResultsText
    @Localized(.profile_no_characters) var noCharactersText

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    /// 통합 캐릭터 목록 (modern 먼저, classic 뒤 — 프로필과 동일한 순서)
    private var combinedCharacters: [CharacterWithAffinity] {
        characterStore.modernCharacters + characterStore.classicCharacters
    }

    /// 검색 필터 — 영문 name과 한국어 korean_name 모두 부분 일치
    private var filteredCharacters: [CharacterWithAffinity] {
        guard !trimmedSearch.isEmpty else { return combinedCharacters }
        return combinedCharacters.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearch) ||
            ($0.korean_name?.localizedCaseInsensitiveContains(trimmedSearch) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                if characterStore.isLoading && characterStore.allCharacters.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredCharacters.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: trimmedSearch.isEmpty ? "sparkles" : "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text(trimmedSearch.isEmpty ? noCharactersText : searchNoResultsText)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredCharacters.enumerated()), id: \.element.id) { index, character in
                                VStack(spacing: 0) {
                                    CharacterCard(
                                        character: character,
                                        onFollowToggle: {
                                            await characterStore.toggleFollowing(characterId: character.id)
                                        },
                                        index: index
                                    )
                                    .onTapGesture {
                                        selectedCharacter = character
                                    }

                                    if character.id != filteredCharacters.last?.id {
                                        Divider()
                                            .padding(.leading, 62)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .modernCard()
                        .padding(.horizontal, 20)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        isSearchFocused = false
                    }
                }
            }
            .background(Color.modernBackground)
            .navigationTitle(findCharactersText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(doneText) {
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(
                        characterStore.followingCharacters.isEmpty ? .secondary : Color(hex: "00C896")
                    )
                }
            }
        }
        .sheet(item: $selectedCharacter) { character in
            CharacterDetailSheet(
                character: character,
                onFollowToggle: {
                    await characterStore.toggleFollowing(characterId: character.id)
                    // 업데이트된 캐릭터 반영
                    if let updated = characterStore.allCharacters.first(where: { $0.id == character.id }) {
                        selectedCharacter = updated
                    }
                }
            )
        }
        .task {
            if characterStore.allCharacters.isEmpty {
                await characterStore.loadAllCharacters()
            }
        }
    }

    // MARK: - Search Field (프로필 검색창과 동일 스펙)
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            TextField(searchPlaceholderText, text: $searchText)
                .font(.system(size: 14, design: .rounded))
                .focused($isSearchFocused)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.pressable)
            }
        }
        // 높이 고정 — TextField의 플레이스홀더/편집 상태 고유 높이 차이로
        // 포커스 순간 필드가 줄어들어 보이는 것 방지
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
                    Color(hex: "00C896").opacity(isSearchFocused ? 0.35 : 0),
                    lineWidth: 1
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchFocused)
        )
        .animation(.easeInOut(duration: 0.15), value: searchText.isEmpty)
    }
}
