//
//  HelpView.swift
//  DiaryFriend
//
//  Help 화면 - 앱 사용 가이드 슬라이드
//

import SwiftUI

// MARK: - Help Slide Model

struct HelpSlide: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String      // Asset 이미지 이름
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
                
                // 하단 75% - 이미지 영역 (하단 꽉 차게)
                ZStack {
                    // 배경 그라데이션
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
    
    private let slides: [HelpSlide] = [
        HelpSlide(
            title: "Follow AI Characters",
            description: "Find and follow AI characters who can chat with you for diary writing and provide insights on your entries.",
            imageName: "help-follow",  // ⭐ Asset 이미지 이름
            iconColor: Color(hex: "00C896")
        ),
        HelpSlide(
            title: "Choose Your AI Friend",
            description: "Select an AI friend to chat with for your diary writing.",
            imageName: "help-choose",  // ⭐ Asset 이미지 이름
            iconColor: Color(hex: "FFD93D")
        ),
        HelpSlide(
            title: "Generate Your Diary",
            description: "Once you've had enough conversation, tap the Generate button to create your diary entry.",
            imageName: "help-generate",  // ⭐ Asset 이미지 이름
            iconColor: Color(hex: "A78BFA")
        ),
        HelpSlide(
            title: "Review and Edit",
            description: "Check the AI-generated diary and customize the content, mood, tags, and photos as you like.",
            imageName: "help-review",  // ⭐ Asset 이미지 이름
            iconColor: Color(hex: "FF7AB2")
        ),
        HelpSlide(
            title: "View Your Diary",
            description: "Check your completed diary. If AI Insight is enabled, AI friends will have left comments based on your entry!",
            imageName: "help-view",  // ⭐ Asset 이미지 이름
            iconColor: Color(hex: "6BCF7F")
        )
    ]
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Content
            VStack(spacing: 0) {
                // 슬라이드 컨텐츠
                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        HelpSlideView(slide: slide)
                            .tag(index)
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
                            Text("Done")
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
}
