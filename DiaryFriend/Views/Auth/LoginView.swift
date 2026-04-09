//
//  LoginView.swift
//  DiaryFriend
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showHelp = false
    @State private var currentPage = 0

    @Localized(.login_subtitle) var loginSubtitle
    @Localized(.login_why_signin) var whySignInText
    @Localized(.login_feature1_title) var feature1Title
    @Localized(.login_feature1_desc) var feature1Desc
    @Localized(.login_feature2_title) var feature2Title
    @Localized(.login_feature2_desc) var feature2Desc
    @Localized(.login_feature3_title) var feature3Title
    @Localized(.login_feature3_desc) var feature3Desc

    private var featurePages: [(title: String, desc: String, icon: String, color: Color)] {
        [
            (feature1Title, feature1Desc, "brain.head.profile", Color(hex: "00C896")),
            (feature2Title, feature2Desc, "bubble.left.and.bubble.right", Color(hex: "FF8C00")),
            (feature3Title, feature3Desc, "chart.line.uptrend.xyaxis", Color(hex: "1E90FF")),
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.modernBackground
                    .ignoresSafeArea()

                // 하단 물결 + 로고 장식
                waveDecorationLayer

                // 콘텐츠
                VStack(spacing: 0) {
                    // 헤더 (왼쪽 정렬)
                    titleSection
                        .padding(.top, 70)

                    // 피처 캐러셀
                    featureCarousel
                        .padding(.top, 24)

                    Spacer()

                    // 로그인 버튼
                    SocialLoginSection(
                        errorMessage: $errorMessage,
                        showError: $showError
                    )
                    .environmentObject(authService)

                    helpLinkSection

                    // 물결 영역 공간 확보
                    Spacer()
                        .frame(height: 160)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
        }
    }

    // MARK: - Title Section (왼쪽 정렬)
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DiaryFriend")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(loginSubtitle)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
    }

    // MARK: - Feature Carousel
    private var featureCarousel: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(featurePages.enumerated()), id: \.offset) { index, page in
                    featurePageView(
                        title: page.title,
                        description: page.desc,
                        icon: page.icon,
                        color: page.color
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 220)

            // 커스텀 인디케이터
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color(hex: "00C896") : Color.secondary.opacity(0.25))
                        .frame(width: index == currentPage ? 8 : 6, height: index == currentPage ? 8 : 6)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Feature Page
    private func featurePageView(title: String, description: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineSpacing(4)
                .padding(.bottom, 10)

            Text(description)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.bottom, 20)

            HStack {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(color.opacity(0.6))
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
    }

    // MARK: - Wave Decoration + Logo
    private var waveDecorationLayer: some View {
        VStack {
            Spacer()
            ZStack(alignment: .top) {
                LoginWaveShape()
                    .fill(Color(hex: "00C896").opacity(0.10))
                    .frame(height: 200)

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                    .offset(y: -40)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Help Link
    private var helpLinkSection: some View {
        Button(action: {
            showHelp = true
        }) {
            Text(whySignInText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .underline()
        }
        .padding(.top, 20)
    }
}

// MARK: - Wave Shape
struct LoginWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: h * 0.35))

        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.15),
            control1: CGPoint(x: w * 0.15, y: h * 0.05),
            control2: CGPoint(x: w * 0.35, y: h * 0.15)
        )

        path.addCurve(
            to: CGPoint(x: w, y: h * 0.3),
            control1: CGPoint(x: w * 0.65, y: h * 0.15),
            control2: CGPoint(x: w * 0.85, y: h * 0.45)
        )

        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()

        return path
    }
}
