//
//  CharacterCard.swift
//  DiaryFriend
//
//  캐릭터 카드 컴포넌트 (다국어 지원)
//

import SwiftUI

struct CharacterCard: View {
    let character: CharacterWithAffinity
    let onFollowToggle: () async -> Void
    let index: Int
    
    // ✅ LocalizationManager 주입
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var isTogglingFollow = false
    
    // ✅ 언어별 표시 텍스트 계산
    private var isKorean: Bool {
        localizationManager.currentLanguage == .korean
    }
    
    private var displayName: String {
        character.localizedName(isKorean: isKorean)
    }
    
    private var displayDescription: String? {
        character.localizedDescription(isKorean: isKorean)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with delayed loading
            ZStack {
                CachedAvatarImage(
                    url: character.avatar_url,
                    size: 45,
                    initial: String(displayName.prefix(1)).uppercased()  // ✅ 다국어 이름 첫 글자
                )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)  // ✅ 다국어 이름
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                if let description = displayDescription {  // ✅ 다국어 설명
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
