//
//  CharacterSelectionView.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/6/25.
//

import SwiftUI

struct CharacterSelectionView: View {
    @StateObject private var characterStore = CharacterStore.shared
    @Binding var isPresented: Bool

    @State private var searchText = ""
    @State private var selectedCharacter: CharacterWithAffinity?
    @State private var isClassicExpanded = true

    @Localized(.ai_insights_find_characters) var findCharactersText
    @Localized(.common_done) var doneText
    @Localized(.profile_classic_characters) var classicCharactersTitle

    // 검색 필터링된 캐릭터
    private var filteredModernCharacters: [CharacterWithAffinity] {
        let modern = characterStore.modernCharacters
        if searchText.isEmpty {
            return modern
        } else {
            return modern.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.korean_name?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    private var filteredClassicCharacters: [CharacterWithAffinity] {
        let classic = characterStore.classicCharacters
        if searchText.isEmpty {
            return classic
        } else {
            return classic.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.korean_name?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    private var hasAnyResults: Bool {
        !filteredModernCharacters.isEmpty || !filteredClassicCharacters.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search characters...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // Character List using existing CharacterCard
                if characterStore.isLoading && characterStore.allCharacters.isEmpty {
                    Spacer()
                    ProgressView("Loading characters...")
                    Spacer()
                } else if !hasAnyResults {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: searchText.isEmpty ? "sparkles" : "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text(searchText.isEmpty ? "No characters available" : "No results found")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Modern Characters
                            if !filteredModernCharacters.isEmpty {
                                LazyVStack(spacing: 0) {
                                    ForEach(Array(filteredModernCharacters.enumerated()), id: \.element.id) { index, character in
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

                                            if character.id != filteredModernCharacters.last?.id {
                                                Divider()
                                                    .padding(.leading, 62)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                                .background(Color.modernSurfacePrimary)
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            }

                            // Classic Characters (Accordion)
                            if !filteredClassicCharacters.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isClassicExpanded.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text(classicCharactersTitle)
                                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                                .foregroundColor(.primary)

                                            Spacer()

                                            Image(systemName: isClassicExpanded ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 4)

                                    if isClassicExpanded {
                                        LazyVStack(spacing: 0) {
                                            ForEach(Array(filteredClassicCharacters.enumerated()), id: \.element.id) { index, character in
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

                                                    if character.id != filteredClassicCharacters.last?.id {
                                                        Divider()
                                                            .padding(.leading, 62)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .background(Color.modernSurfacePrimary)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
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
}
