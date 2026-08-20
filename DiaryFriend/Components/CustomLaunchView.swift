//
//  CustomLaunchView.swift
//  DiaryFriend
//
//  앱 로딩 스플래시. 솔리드 배경 + 글자별 순차 등장 워드마크 + 밑줄 드로잉 + 시간대별 greeting.
//

import SwiftUI

struct CustomLaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var revealedLetters: Set<Int> = []
    @State private var underlineProgress: CGFloat = 0
    @State private var greetingVisible: Bool = false

    @Localized(.app_diary_friend) private var appName

    // MARK: - Motion spec

    /// 글자당 등장 간격. 11글자 기준 전체 워드마크가 약 0.5초 안에 다 뜨도록 유지.
    private let letterStagger: Double = 0.045
    private let letterDuration: Double = 0.35
    private let firstLetterDelay: Double = 0.1

    /// 마지막 글자가 착지하는 시점에 맞물려 밑줄이 그어지기 시작.
    private var underlineDelay: Double {
        firstLetterDelay + Double(letters.count - 1) * letterStagger + 0.12
    }

    private var greetingDelay: Double { underlineDelay + 0.33 }

    // MARK: - Derived

    private var letters: [Character] {
        Array(appName.uppercased())
    }

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

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.modernBackground
                .ignoresSafeArea()

            VStack(spacing: 18) {
                wordmark

                Text(greetingText)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .opacity(greetingVisible ? 1 : 0)
                    .offset(y: greetingVisible ? 0 : 8)
            }
            // 기하학적 중앙보다 살짝 위가 시각적 중앙으로 보임
            .offset(y: -40)
        }
        .onAppear { startEntrance() }
    }

    // MARK: - Subviews

    private var wordmark: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                    Text(String(letter))
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .opacity(revealedLetters.contains(index) ? 1 : 0)
                        .offset(y: revealedLetters.contains(index) ? 0 : 12)
                        .blur(radius: revealedLetters.contains(index) ? 0 : 6)
                }
            }

            // 밑줄: scaleEffect 로만 늘어나므로 레이아웃 폭(=워드마크 폭)은 고정.
            Capsule()
                .fill(brandGreen)
                .frame(height: 3)
                .scaleEffect(x: underlineProgress, y: 1, anchor: .leading)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(appName)
    }

    // MARK: - Animations

    private func startEntrance() {
        if reduceMotion {
            // 모션 민감 사용자: 모든 요소 즉시 최종 상태로
            revealedLetters = Set(letters.indices)
            underlineProgress = 1
            greetingVisible = true
            return
        }

        // 글자별 순차 등장: 아래에서 블러가 걷히며 떠오름
        for index in letters.indices {
            withAnimation(
                .easeOut(duration: letterDuration)
                    .delay(firstLetterDelay + Double(index) * letterStagger)
            ) {
                _ = revealedLetters.insert(index)
            }
        }

        // 밑줄 드로잉: 왼쪽→오른쪽, 끝에서 살짝 오버슈트 후 정착
        withAnimation(
            .spring(response: 0.5, dampingFraction: 0.68)
                .delay(underlineDelay)
        ) {
            underlineProgress = 1
        }

        // 인사말은 밑줄이 그어진 뒤 마지막에
        withAnimation(.easeOut(duration: 0.45).delay(greetingDelay)) {
            greetingVisible = true
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
