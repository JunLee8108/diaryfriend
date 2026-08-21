//
//  PaperBackground.swift
//  DiaryFriend
//
//  일기 읽기 화면용 종이 질감 배경.
//  쿨 오프화이트 베이스(누런 톤 배제) + 생성 노이즈 그레인 타일.
//  다크 모드는 기존 배경을 유지하고 밝은 입자만 아주 옅게 얹는다.
//

import SwiftUI

struct PaperBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    /// 그레인 강도 — 의식하면 보이고, 의식하지 않으면 안 보이는 수준이 목표
    private var grainOpacity: Double {
        colorScheme == .dark ? 0.18 : 0.45
    }

    private var baseColor: Color {
        colorScheme == .dark
            ? Color.modernBackground
            : Color(hex: "FAFAF8")  // 새 노트 속지 느낌의 쿨 오프화이트
    }

    var body: some View {
        ZStack {
            baseColor

            // 384px(3x → 128pt) 타일 — GPU 타일링이라 비용 거의 없음
            Image("PaperGrain")
                .resizable(resizingMode: .tile)
                .opacity(grainOpacity)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview("Light") {
    PaperBackground()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    PaperBackground()
        .preferredColorScheme(.dark)
}
