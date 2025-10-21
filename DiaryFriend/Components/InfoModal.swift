//
//  InfoModal.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/1/25.
//

import SwiftUI

struct InfoModal: View {
    @Binding var isPresented: Bool
    
    // 필수 프로퍼티
    let title: String
    let message: String
    
    // 옵션 프로퍼티
    var icon: String = "info.circle"
    var iconColor: Color = Color(hex: "87CEEB")
    var buttonText: String = "OK"
    
    // 액션
    var onDismiss: (() -> Void)? = nil
    
    // 내부 상태
    @State private var showModal = false
    
    var body: some View {
        ZStack {
            if isPresented {
                // 배경 오버레이 - showModal이 false가 되면 즉시 터치 통과
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .allowsHitTesting(showModal)  // showModal이 false면 터치 통과
                    .onTapGesture {
                        if showModal {
                            dismissModal()
                        }
                    }
                    .transition(.opacity)
                
                // 모달 카드
                modalContent
                    .scaleEffect(showModal ? 1 : 0.9)
                    .opacity(showModal ? 1 : 0)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showModal)
        .onChange(of: isPresented) { oldValue, newValue in
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showModal = true
                }
            } else {
                showModal = false
            }
        }
    }
    
    private var modalContent: some View {
        VStack(spacing: 20) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
            }
            
            // 텍스트 영역
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // 버튼 영역
            Button(action: {
                dismissModal()
            }) {
                Text(buttonText)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(iconColor)
                    )
            }
        }
        .padding(24)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.modernSurfacePrimary)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
//        .offset(y: -10) // 위로 40포인트 이동
    }
    
    // 액션 헬퍼
    private func dismissModal() {
        // 1. 모달 카드 애니메이션 먼저 (showModal = false로 터치 즉시 통과)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showModal = false
        }
        
        // 2. 배경 제거는 약간의 딜레이 후 (시각적 연속성)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isPresented = false
        }
        
        // 3. onDismiss 콜백 즉시 실행
        onDismiss?()
    }
}

// MARK: - ViewModifier for easier usage

struct InfoModalModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    var icon: String = "info.circle"
    var iconColor: Color = Color(hex: "87CEEB")
    var buttonText: String = "OK"
    var onDismiss: (() -> Void)? = nil
    
    func body(content: Content) -> some View {
        content
            .overlay {
                InfoModal(
                    isPresented: $isPresented,
                    title: title,
                    message: message,
                    icon: icon,
                    iconColor: iconColor,
                    buttonText: buttonText,
                    onDismiss: onDismiss
                )
            }
    }
}

// MARK: - View Extension

extension View {
    func infoModal(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        icon: String = "info.circle",
        iconColor: Color = Color(hex: "87CEEB"),
        buttonText: String = "OK",
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            InfoModalModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                icon: icon,
                iconColor: iconColor,
                buttonText: buttonText,
                onDismiss: onDismiss
            )
        )
    }
}

// MARK: - Preview

#Preview("Future Date Info") {
    struct PreviewWrapper: View {
        @State private var showInfo = true
        
        var body: some View {
            VStack {
                Button("Show Info Modal") {
                    showInfo = true
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
            .infoModal(
                isPresented: $showInfo,
                title: "Future Date",
                message: "You cannot create entries for future dates.",
                icon: "calendar.badge.exclamationmark"
            )
        }
    }
    
    return PreviewWrapper()
}

#Preview("General Info") {
    struct PreviewWrapper: View {
        @State private var showInfo = true
        
        var body: some View {
            VStack {
                Button("Show Info") {
                    showInfo = true
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
            .infoModal(
                isPresented: $showInfo,
                title: "Success",
                message: "Your changes have been saved successfully.",
                icon: "checkmark.circle",
                iconColor: Color(hex: "4CAF50")
            )
        }
    }
    
    return PreviewWrapper()
}

#Preview("Warning Info") {
    struct PreviewWrapper: View {
        @State private var showInfo = true
        
        var body: some View {
            VStack {
                Button("Show Warning") {
                    showInfo = true
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
            .infoModal(
                isPresented: $showInfo,
                title: "Network Error",
                message: "Please check your internet connection and try again.",
                icon: "wifi.slash",
                iconColor: Color(hex: "FF9800")
            )
        }
    }
    
    return PreviewWrapper()
}
