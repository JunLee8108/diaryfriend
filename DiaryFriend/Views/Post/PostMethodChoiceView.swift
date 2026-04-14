// Views/Post/PostMethodChoiceView.swift
import SwiftUI

struct PostMethodChoiceView: View {
    let selectedDate: Date
    @StateObject private var creationManager = PostCreationManager.shared
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    // ⭐ 다국어 적용
    @Localized(.post_method_choice_title) var choiceTitle
    @Localized(.post_method_ai_title) var aiTitle
    @Localized(.post_method_ai_description) var aiDescription
    @Localized(.post_method_manual_title) var manualTitle
    @Localized(.post_method_manual_description) var manualDescription
    
    // Navigation states
    @State private var navigateToAISelect = false
    @State private var navigateToManual = false
    
    // ⭐ DateUtility 사용으로 간소화
    private var dateTitle: String {
        DateUtility.shared.monthDay(from: selectedDate)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer(minLength: 50)
                
                // Main Content
                VStack(spacing: 30) {
                    // Title section with bubble style
                    VStack(spacing: 8) {
                        Text(dateTitle)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(choiceTitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    // Console pad buttons
                    HStack(spacing: 16) {
                        // AI option pad
                        Button(action: {
                            navigationCoordinator.push(.aiSelect)
                        }) {
                            ConsolePadButton(
                                icon: "bubble.left.and.bubble.right.fill",
                                iconColor: Color(hex: "00A077"),
                                title: aiTitle,
                                description: aiDescription
                            )
                        }
                        .buttonStyle(ConsolePadButtonStyle())

                        // Manual writing pad
                        Button(action: {
                            navigationCoordinator.push(.manualWrite)
                        }) {
                            ConsolePadButton(
                                icon: "pencil",
                                iconColor: Color(hex: "FFB6A3"),
                                title: manualTitle,
                                description: manualDescription
                            )
                        }
                        .buttonStyle(ConsolePadButtonStyle())
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 120)
                
                Spacer(minLength: 50)
            }
        }
        .onAppear {
            creationManager.setSelectedDate(selectedDate)
        }
        .background(Color.modernBackground)
    }
}

// MARK: - Console Pad Button Style (Press Animation)

private struct ConsolePadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Console Pad Button Component

private struct ConsolePadButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    @Environment(\.colorScheme) private var colorScheme

    private var iconSize: CGFloat {
        switch icon {
        case "bubble.left.and.bubble.right.fill":
            return 26
        default:
            return 32
        }
    }

    // 베이스(받침) 색상
    private var baseColor: Color {
        colorScheme == .dark
            ? Color(hex: "1A1A1A")
            : Color(hex: "D8D8D8")
    }

    // 상단면 색상
    private var surfaceColor: Color {
        colorScheme == .dark
            ? Color(hex: "2A2A2A")
            : Color(hex: "F0F0F0")
    }

    // 상단면 하이라이트
    private var highlightColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.9)
    }

    // 하단 엣지(그림자 역할)
    private var edgeColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.6)
            : Color.black.opacity(0.12)
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width

            ZStack {
                // Layer 1: 베이스 받침 (버튼이 올라앉는 바닥)
                RoundedRectangle(cornerRadius: 22)
                    .fill(baseColor)

                // Layer 2: 하단 엣지 (두께감)
                RoundedRectangle(cornerRadius: 20)
                    .fill(edgeColor)
                    .padding(2)

                // Layer 3: 상단면 (볼록한 버튼 면)
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                surfaceColor,
                                colorScheme == .dark
                                    ? Color(hex: "222222")
                                    : Color(hex: "E4E4E4")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.horizontal, 2)
                    .padding(.top, 2)
                    .padding(.bottom, 5)

                // Layer 4: 상단 하이라이트 (빛 반사)
                RoundedRectangle(cornerRadius: 19)
                    .stroke(highlightColor, lineWidth: 1)
                    .padding(.horizontal, 3)
                    .padding(.top, 3)
                    .padding(.bottom, 6)

                // Layer 5: 콘텐츠
                VStack(spacing: 10) {
                    Spacer()

                    // 아이콘
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.12))
                            .frame(width: 56, height: 56)

                        Image(systemName: icon)
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(iconColor)
                    }

                    // 타이틀
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    // 설명
                    Text(description)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 3)
            }
            .frame(width: size, height: size)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.08), radius: 8, x: 0, y: 4)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 2, x: 0, y: 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
