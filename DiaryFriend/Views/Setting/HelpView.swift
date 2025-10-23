//
//  HelpView.swift
//  DiaryFriend
//

import SwiftUI

// MARK: - Help Slide Model

struct HelpSlide: Identifiable {
    let id: Int  // ← UUID 대신 Int 사용!
    let title: String
    let description: String
    let imageName: String
    let iconColor: Color
}

// MARK: - Help Slide View (Single Slide Component)

struct HelpSlideView: View {
    let slide: HelpSlide
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 상단 25% - 텍스트 영역
                VStack(alignment: .leading, spacing: 12) {
                    Text(slide.title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(slide.description)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: geometry.size.height * 0.25)
                .padding(.horizontal, 32)
                .padding(.top, 30)
                
                Spacer(minLength: 0)
                
                // 하단 75% - 이미지 영역
                ZStack {
                    // 배경 그라디언션
                    LinearGradient(
                        colors: [
                            slide.iconColor.opacity(0.15),
                            slide.iconColor.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // 이미지 (Asset)
                    Image(slide.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                }
                .frame(height: geometry.size.height * 0.75)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Help View (Main Container)

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    // ⭐ 다국어 적용
    @Localized(.help_done) var doneText
    
    @Localized(.help_slide1_title) var slide1Title
    @Localized(.help_slide1_description) var slide1Desc
    @Localized(.help_slide2_title) var slide2Title
    @Localized(.help_slide2_description) var slide2Desc
    @Localized(.help_slide3_title) var slide3Title
    @Localized(.help_slide3_description) var slide3Desc
    @Localized(.help_slide4_title) var slide4Title
    @Localized(.help_slide4_description) var slide4Desc
    @Localized(.help_slide5_title) var slide5Title
    @Localized(.help_slide5_description) var slide5Desc
    
    // ⭐ computed property (ID는 고정값 사용)
    private var slides: [HelpSlide] {
        [
            HelpSlide(
                id: 0,  // ← 고정 ID
                title: slide1Title,
                description: slide1Desc,
                imageName: "help-follow",
                iconColor: Color(hex: "00C896")
            ),
            HelpSlide(
                id: 1,  // ← 고정 ID
                title: slide2Title,
                description: slide2Desc,
                imageName: "help-choose",
                iconColor: Color(hex: "FFD93D")
            ),
            HelpSlide(
                id: 2,  // ← 고정 ID
                title: slide3Title,
                description: slide3Desc,
                imageName: "help-generate",
                iconColor: Color(hex: "A78BFA")
            ),
            HelpSlide(
                id: 3,  // ← 고정 ID
                title: slide4Title,
                description: slide4Desc,
                imageName: "help-review",
                iconColor: Color(hex: "FF7AB2")
            ),
            HelpSlide(
                id: 4,  // ← 고정 ID
                title: slide5Title,
                description: slide5Desc,
                imageName: "help-view",
                iconColor: Color(hex: "6BCF7F")
            )
        ]
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Content
            VStack(spacing: 0) {
                // 슬라이드 컨텐츠
                TabView(selection: $currentPage) {
                    ForEach(slides) { slide in
                        HelpSlideView(slide: slide)
                            .tag(slide.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // 하단 네비게이션
                HStack(spacing: 20) {
                    // Previous Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if currentPage > 0 {
                                currentPage -= 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(currentPage > 0 ? Color(hex: "00C896") : .secondary.opacity(0.3))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(currentPage <= 0)
                    
                    Spacer()
                    
                    // Done / Next Button
                    if currentPage == slides.count - 1 {
                        Button(action: {
                            dismiss()
                        }) {
                            Text(doneText)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(height: 44)
                                .frame(minWidth: 100)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "00C896"))
                                        .shadow(color: Color(hex: "00C896").opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                        }
                    } else {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if currentPage < slides.count - 1 {
                                    currentPage += 1
                                }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "00C896"))
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
            
            // Close Button (Top Right)
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
        .background(Color.modernBackground)
    }
}

// MARK: - Preview

#Preview {
    HelpView()
        .environmentObject(LocalizationManager.shared)
}
