import SwiftUI

struct ConfirmationModal: View {
    @Binding var isPresented: Bool
    
    // 필수 프로퍼티
    let title: String
    let message: String
    
    // 옵션 프로퍼티
    var icon: String = "exclamationmark.circle"
    var iconColor: Color = Color(hex: "87CEEB")
    var confirmText: String = "Confirm"
    var cancelText: String = "Cancel"
    var isDestructive: Bool = false
    
    // 액션
    var onConfirm: () async -> Void
    var onCancel: (() -> Void)? = nil
    
    // 내부 상태
    @State private var isProcessing = false
    @State private var showModal = false
    
    var body: some View {
        ZStack {
            if isPresented {
                // 배경 오버레이 - showModal이 false가 되면 즉시 터치 통과
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .allowsHitTesting(showModal)  // showModal이 false면 터치 통과
                    .onTapGesture {
                        if !isProcessing && showModal {
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
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(iconBackgroundColor)
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
            HStack(spacing: 12) {
                // 취소 버튼
                Button(action: {
                    if !isProcessing {
                        dismissModal()
                    }
                }) {
                    Text(cancelText)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                )
                        )
                }
                .disabled(isProcessing)
                
                // 확인 버튼
                Button(action: {
                    if !isProcessing {
                        confirmAction()
                    }
                }) {
                    ZStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(confirmText)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(confirmButtonColor)
                    )
                }
                .disabled(isProcessing)
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
        .offset(y: -30) // 위로 50포인트 이동
    }
    
    // 컬러 헬퍼
    private var iconBackgroundColor: Color {
        isDestructive ? Color(hex: "FF6B6B") : iconColor
    }
    
    private var confirmButtonColor: Color {
        isDestructive ? Color(hex: "FF6B6B") : Color(hex: "87CEEB")
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
        
        // 3. onCancel 콜백 즉시 실행
        onCancel?()
    }
    
    private func confirmAction() {
        isProcessing = true
        
        Task {
            await onConfirm()
            
            await MainActor.run {
                isProcessing = false
                
                // 모달 애니메이션 먼저
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showModal = false
                }
                
                // 배경 제거는 약간 후
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - ViewModifier for easier usage

struct ConfirmationModalModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    var icon: String = "exclamationmark.circle"
    var iconColor: Color = Color(hex: "87CEEB")
    var confirmText: String = "Confirm"
    var cancelText: String = "Cancel"
    var isDestructive: Bool = false
    var onConfirm: () async -> Void
    var onCancel: (() -> Void)? = nil
    
    func body(content: Content) -> some View {
        content
            .overlay {
                ConfirmationModal(
                    isPresented: $isPresented,
                    title: title,
                    message: message,
                    icon: icon,
                    iconColor: iconColor,
                    confirmText: confirmText,
                    cancelText: cancelText,
                    isDestructive: isDestructive,
                    onConfirm: onConfirm,
                    onCancel: onCancel
                )
            }
    }
}

// MARK: - View Extension

extension View {
    func confirmationModal(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        icon: String = "exclamationmark.circle",
        iconColor: Color = Color(hex: "87CEEB"),
        confirmText: String = "Confirm",
        cancelText: String = "Cancel",
        isDestructive: Bool = false,
        onConfirm: @escaping () async -> Void,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            ConfirmationModalModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                icon: icon,
                iconColor: iconColor,
                confirmText: confirmText,
                cancelText: cancelText,
                isDestructive: isDestructive,
                onConfirm: onConfirm,
                onCancel: onCancel
            )
        )
    }
}

// MARK: - Preview

#Preview("Delete Confirmation") {
    struct PreviewWrapper: View {
        @State private var showDelete = true
        
        var body: some View {
            VStack {
                Button("Show Delete Modal") {
                    showDelete = true
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
            .confirmationModal(
                isPresented: $showDelete,
                title: "Delete Post",
                message: "Are you sure you want to delete this post? This action cannot be undone.",
                icon: "trash",
                confirmText: "Delete",
                isDestructive: true,
                onConfirm: {
                    // Simulate network delay
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    print("Deleted!")
                }
            )
        }
    }
    
    return PreviewWrapper()
}

#Preview("General Confirmation") {
    struct PreviewWrapper: View {
        @State private var showConfirm = true
        
        var body: some View {
            VStack {
                Button("Show Confirmation") {
                    showConfirm = true
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
            .confirmationModal(
                isPresented: $showConfirm,
                title: "Save Changes",
                message: "Would you like to save your changes before leaving?",
                icon: "square.and.arrow.down",
                confirmText: "Save",
                cancelText: "Don't Save",
                onConfirm: {
                    // Simulate save
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    print("Saved!")
                }
            )
        }
    }
    
    return PreviewWrapper()
}
