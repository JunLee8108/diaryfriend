//
//  CharacterCard.swift
//  DiaryFriend
//
//  캐릭터 카드 컴포넌트 (지연 로딩 적용)
//

import SwiftUI

struct CharacterCard: View {
    let character: CharacterWithAffinity
    let onFollowToggle: () async -> Void
    let index: Int  // 추가: 순차 로딩용
    
    @State private var isTogglingFollow = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with delayed loading
            ZStack {
                CachedAvatarImage(
                    url: character.avatar_url,
                    size: 45,
                    initial: String(character.name.prefix(1)).uppercased()
                )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                if let description = character.description {
                    Text(description)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Follow Button with Icon
            Button(action: {
                Task {
                    isTogglingFollow = true
                    await onFollowToggle()
                    isTogglingFollow = false
                }
            }) {
                if isTogglingFollow {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                        .frame(width: 44, height: 44)
                        .tint(Color(hex: "FF6B6B"))
                } else {
                    Image(systemName: character.isFollowing ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(character.isFollowing ? Color(hex: "FF6B6B") : .gray)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
            }
            .disabled(isTogglingFollow)
        }
        .padding(12)
        .contentShape(Rectangle())
    }
}
