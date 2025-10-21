//
//  ModernHighlight.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/7/25.
//  형광펜 스타일 하이라이트 효과
//

import SwiftUI

// MARK: - Modern Highlight ViewModifier
struct ModernHighlight: ViewModifier {
    let color: Color
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(opacity))
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height * 0.4
                        )
                        .offset(y: geometry.size.height * 0.4)
                }
            )
    }
}

// MARK: - View Extension
extension View {
    /// 형광펜 스타일의 모던한 하이라이트 효과를 추가합니다
    /// - Parameters:
    ///   - color: 하이라이트 색상 (기본값: .primary)
    ///   - opacity: 투명도 (기본값: 0.15)
    /// - Returns: 하이라이트가 적용된 View
    func modernHighlight(
        color: Color = .secondary,
        opacity: Double = 0.15
    ) -> some View {
        self.modifier(ModernHighlight(color: color, opacity: opacity))
    }
}
