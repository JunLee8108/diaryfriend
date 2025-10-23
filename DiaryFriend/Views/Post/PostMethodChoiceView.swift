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
                VStack(spacing: 40) {
                    // Title section with bubble style
                    VStack(spacing: 8) {
                        Text(dateTitle)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(choiceTitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    // Choice cards
                    VStack(spacing: 20) {
                        // AI option bubble card
                        Button(action: {
                            navigationCoordinator.push(.aiSelect)
                        }) {
                            BubbleCard(
                                icon: "bubble.left.and.bubble.right.fill",
                                iconColor: Color(hex: "00A077"),
                                title: aiTitle,
                                description: aiDescription
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Manual writing bubble card
                        Button(action: {
                            navigationCoordinator.push(.manualWrite)
                        }) {
                            BubbleCard(
                                icon: "pencil",
                                iconColor: Color(hex: "FFB6A3"),
                                title: manualTitle,
                                description: manualDescription
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 100)
                
                Spacer(minLength: 50)
            }
        }
        .onAppear {
            creationManager.setSelectedDate(selectedDate)
        }
        .background(Color.modernBackground)
    }
}

// MARK: - Modern Bubble Card Component

private struct BubbleCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    // 아이콘별 크기 조정
    private var iconSize: CGFloat {
        switch icon {
        case "bubble.left.and.bubble.right.fill":
            return 18  // AI 채팅 아이콘은 작게
        default:
            return 26  // 나머지는 기본 크기
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon circle - 통일된 크기와 스타일
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Text content - 타이포그래피 개선
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 8)
            
            // Chevron indicator - 인터랙션 암시
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.modernSurfacePrimary)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                .shadow(color: Color.black.opacity(0.02), radius: 16, x: 0, y: 4)
        )
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
