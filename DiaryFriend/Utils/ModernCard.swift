//
//  ModernCard.swift
//  DiaryFriend
//
//  표준 서피스 카드 스타일. radius/그림자/하이라이트 스펙을 한 곳에서 관리한다.
//  이중 그림자(밀착+환경)로 깊이감을, 0.5pt 헤어라인 하이라이트로 재질감을 만든다.
//  다크모드에서는 그림자가 거의 보이지 않으므로 헤어라인이 카드 경계를 정의한다.
//

import SwiftUI

private struct ModernCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.modernSurfacePrimary)
                    // 밀착 그림자: 카드가 표면에 닿아 있는 느낌
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.30 : 0.06),
                        radius: 2.5, x: 0, y: 1
                    )
                    // 환경 그림자: 넓고 옅은 깊이감
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.22 : 0.05),
                        radius: 14, x: 0, y: 6
                    )
            )
            .overlay(
                // 헤어라인 하이라이트: 라이트=윗면 빛 반사, 다크=경계 정의
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color.white.opacity(0.10), Color.white.opacity(0.03)]
                                : [Color.white.opacity(0.90), Color.white.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
                    .allowsHitTesting(false)
            )
    }
}

extension View {
    /// 표준 서피스 카드: modernSurfacePrimary 배경 + radius 20 + 이중 그림자 + 헤어라인
    func modernCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(ModernCardModifier(cornerRadius: cornerRadius))
    }
}
