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
    
    // 검색 필터링된 캐릭터
    private var filteredCharacters: [CharacterWithAffinity] {
        if searchText.isEmpty {
            return characterStore.allCharacters
        } else {
            return characterStore.searchCharacters(query: searchText)
        }
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
                } else if filteredCharacters.isEmpty {
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
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredCharacters.enumerated()), id: \.element.id) { index, character in
                                VStack(spacing: 0) {
                                    // 기존 CharacterCard 재사용
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
                        .background(Color.modernSurfacePrimary)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .background(Color.modernBackground)
            .navigationTitle("Find AI Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
