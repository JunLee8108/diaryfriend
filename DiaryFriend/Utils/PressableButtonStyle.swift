//
//  PressableButtonStyle.swift
//  DiaryFriend
//
//  공용 눌림 피드백: 누르는 동안 살짝 축소 + 어두워지고, 뗄 때 스프링 복귀.
//  PlainButtonStyle의 무반응을 대체하는 기본 촉감 레이어.
//

import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    /// 기본 눌림 피드백 (scale 0.97)
    static var pressable: PressableButtonStyle { PressableButtonStyle() }

    /// 큰 카드형 요소용 — 축소 폭을 줄여 과하지 않게
    static var pressableCard: PressableButtonStyle { PressableButtonStyle(scale: 0.985) }
}
