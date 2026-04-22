//
//  CustomLaunchView.swift
//  DiaryFriend
//
//  앱 로딩 스플래시. MeshGradient 배경 + 스프링 로고 + 시간대별 greeting.
//

import SwiftUI

struct CustomLaunchView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var logoVisible: Bool = false
    @State private var titleVisible: Bool = false
    @State private var greetingVisible: Bool = false
    @State private var glowScale: CGFloat = 1.0
    @State private var meshPhase: Float = 0

    @Localized(.app_diary_friend) private var appName

    // MARK: - Derived

    /// 시간대별 greeting (morning / afternoon / evening / night)
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let key: LocalizationKey
        switch hour {
        case 5..<12:  key = .greeting_morning
        case 12..<17: key = .greeting_afternoon
        case 17..<22: key = .greeting_evening
        default:      key = .greeting_night
        }
        return LocalizationManager.shared.localized(key)
    }

    private var brandGreen: Color { Color(hex: "00C896") }

    /// 3×3 mesh 그리드의 9개 색상. 라이트/다크 모드별 팔레트.
    private var meshColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: "0A1A14"),  Color(hex: "0F3D2E"),           Color(hex: "0A1A24"),
                Color(hex: "0A2A1E"),  brandGreen.opacity(0.38),        Color(hex: "0A1E2E"),
                Color(hex: "121212"),  Color(hex: "1A2D38"),           Color(hex: "121212")
            ]
        } else {
            return [
                Color(hex: "F8F9FA"),  Color(hex: "D7F3E6"),           Color(hex: "EAF4FF"),
                Color(hex: "E4F7ED"),  brandGreen.opacity(0.22),        Color(hex: "E6EEFB"),
                Color(hex: "F8F9FA"),  Color(hex: "E5EEFB"),           Color(hex: "F8F9FA")
            ]
        }
    }

    /// meshPhase 에 따라 중간 컨트롤 포인트가 흐르듯 움직여 색이 섞이는 효과.
    private var meshPoints: [SIMD2<Float>] {
        let p = meshPhase
        return [
            SIMD2<Float>(0, 0),
            SIMD2<Float>(0.5 + 0.18 * sin(p),       0),
            SIMD2<Float>(1, 0),
            SIMD2<Float>(0, 0.5 + 0.12 * cos(p)),
            SIMD2<Float>(0.5, 0.5),
            SIMD2<Float>(1, 0.5 + 0.12 * sin(p + 0.8)),
            SIMD2<Float>(0, 1),
            SIMD2<Float>(0.5 + 0.18 * cos(p),       1),
            SIMD2<Float>(1, 1)
        ]
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Opaque base — mesh 의 반투명 영역으로 auth/loading 화면이 비치는 것 방지.
            Color.modernBackground
                .ignoresSafeArea()

            background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                logoWithGlow
                    .scaleEffect(logoVisible ? 1.0 : 0.85)
                    .opacity(logoVisible ? 1 : 0)

                Text(appName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : 8)

                Text(greetingText)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(brandGreen)
                    .opacity(greetingVisible ? 1 : 0)
                    .offset(y: greetingVisible ? 0 : 8)
            }
        }
        .onAppear { startEntrance() }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var background: some View {
        if reduceMotion {
            Color.modernBackground
        } else {
            MeshGradient(
                width: 3,
                height: 3,
                points: meshPoints,
                colors: meshColors
            )
        }
    }

    private var logoWithGlow: some View {
        ZStack {
            // 브랜드 그린 breathing halo
            Circle()
                .fill(brandGreen.opacity(0.28))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .scaleEffect(reduceMotion ? 1.0 : glowScale)

            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 112)
        }
    }

    // MARK: - Animations

    private func startEntrance() {
        if reduceMotion {
            // 모션 민감 사용자: 모든 요소 즉시 최종 상태로
            logoVisible = true
            titleVisible = true
            greetingVisible = true
            return
        }

        // 로고 스프링 등장
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            logoVisible = true
        }
        // 타이틀 stagger
        withAnimation(.easeOut(duration: 0.45).delay(0.18)) {
            titleVisible = true
        }
        // 인사말 stagger
        withAnimation(.easeOut(duration: 0.45).delay(0.32)) {
            greetingVisible = true
        }
        // 로고 주변 halo breathing (2.2s 주기)
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            glowScale = 1.12
        }
        // Mesh 흐름 애니메이션 (8s 주기, GPU 부담 낮게)
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
            meshPhase = .pi
        }
    }
}

#Preview("Light") {
    CustomLaunchView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CustomLaunchView()
        .preferredColorScheme(.dark)
}
