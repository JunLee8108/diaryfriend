//
//  ModernCard.swift
//  DiaryFriend
//
//  표준 서피스 카드 스타일. radius/그림자 스펙을 한 곳에서 관리한다.
//  (기존에 화면마다 radius 16/20, 그림자 3~4벌이 혼용되던 것을 통일)
//

import SwiftUI

extension View {
    /// 표준 서피스 카드: modernSurfacePrimary 배경 + radius 20 + 통일 그림자
    func modernCard(cornerRadius: CGFloat = 20) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.modernSurfacePrimary)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
        )
    }
}
