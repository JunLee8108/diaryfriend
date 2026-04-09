//
//  LoginView.swift
//  DiaryFriend
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showHelp = false  // Help Sheet State

    @Localized(.login_subtitle) var loginSubtitle
    @Localized(.login_why_signin) var whySignInText

    var body: some View {
        NavigationStack {
            ZStack {
                Color.modernBackground
                    .ignoresSafeArea()

                // 하단 물결 + 로고 장식
                waveDecorationLayer

                // 콘텐츠
                VStack(spacing: 0) {
                    Spacer()

                    titleSection

                    Spacer()

                    SocialLoginSection(
                        errorMessage: $errorMessage,
                        showError: $showError
                    )
                    .environmentObject(authService)

                    helpLinkSection

                    Spacer()
                    Spacer()
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

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 10) {
            Text("DiaryFriend")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(loginSubtitle)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(0.3)
        }
    }

    // MARK: - Wave Decoration + Logo
    private var waveDecorationLayer: some View {
        VStack {
            Spacer()
            ZStack(alignment: .top) {
                // 물결 배경
                LoginWaveShape()
                    .fill(Color(hex: "00C896").opacity(0.10))
                    .frame(height: 200)

                // 물결 위 로고
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

        // 첫 번째 곡선 (왼쪽 → 중앙)
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.15),
            control1: CGPoint(x: w * 0.15, y: h * 0.05),
            control2: CGPoint(x: w * 0.35, y: h * 0.15)
        )

        // 두 번째 곡선 (중앙 → 오른쪽)
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.3),
            control1: CGPoint(x: w * 0.65, y: h * 0.15),
            control2: CGPoint(x: w * 0.85, y: h * 0.45)
        )

        // 하단 채움
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()

        return path
    }
}
