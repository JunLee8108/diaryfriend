//
//  DeleteAccountModal.swift
//  DiaryFriend
//
//  계정 삭제 전용 모달 - 텍스트 입력 확인 포함
//

import SwiftUI

struct DeleteAccountModal: View {
    @Binding var isPresented: Bool
    
    // 액션
    var onConfirm: () async -> Void
    var onCancel: (() -> Void)? = nil
    
    // 내부 상태
    @State private var inputText = ""
    @State private var isProcessing = false
    @State private var showModal = false
    @FocusState private var isInputFocused: Bool
    
    private let requiredText = "DELETE ACCOUNT"
    
    private var isDeleteEnabled: Bool {
        inputText == requiredText
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                // 배경 오버레이
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .allowsHitTesting(showModal)
                    .onTapGesture {
                        if !isProcessing && showModal {
                            if isInputFocused {
                                // 포커스되어 있으면 포커스만 해제
                                isInputFocused = false
                            } else {
                                // 포커스 안되어 있으면 모달 닫기
                                dismissModal()
                            }
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
                inputText = "" // 모달 닫을 때 입력 초기화
                isInputFocused = false
            }
        }
    }
    
    private var modalContent: some View {
        VStack(spacing: 20) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(Color(hex: "FF6B6B").opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "FF6B6B"))
            }
            
            // 텍스트 영역
            VStack(spacing: 4) {
                Text("Delete Account?")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("This action cannot be undone.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // 입력 필드 영역
            VStack(alignment: .leading, spacing: 8) {
                Text("Type \"\(requiredText)\" to confirm:")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                TextField("", text: $inputText)
                    .focused($isInputFocused)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isDeleteEnabled ? Color(hex: "FF6B6B") : Color.gray.opacity(0.2),
                                lineWidth: 1.5
                            )
                    )
                    .contentShape(Rectangle()) // 이 줄 추가
                    .onTapGesture {
                        isInputFocused = true
                    }
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .disabled(isProcessing)
            }
            
            // 버튼 영역
            HStack(spacing: 12) {
                // 취소 버튼
                Button(action: {
                    if !isProcessing {
                        dismissModal()
                    }
                }) {
                    Text("Cancel")
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
                
                // 삭제 버튼
                Button(action: {
                    if !isProcessing && isDeleteEnabled {
                        confirmAction()
                    }
                }) {
                    ZStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Delete")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isDeleteEnabled ? Color(hex: "FF6B6B") : Color.gray.opacity(0.3))
                    )
                }
                .disabled(isProcessing || !isDeleteEnabled)
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
        .offset(y: -30)
    }
    
    // 액션 헬퍼
    private func dismissModal() {
        // 키보드 내리기
        isInputFocused = false
        
        // 모달 애니메이션
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showModal = false
        }
        
        // 배경 제거
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isPresented = false
        }
        
        // onCancel 콜백
        onCancel?()
    }
    
    private func confirmAction() {
        // 키보드 내리기
        isInputFocused = false
        
        isProcessing = true
        
        Task {
            await onConfirm()
            
            await MainActor.run {
                isProcessing = false
                
                // 모달 애니메이션
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showModal = false
                }
                
                // 배경 제거
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - ViewModifier for easier usage

struct DeleteAccountModalModifier: ViewModifier {
    @Binding var isPresented: Bool
    var onConfirm: () async -> Void
    var onCancel: (() -> Void)? = nil
    
    func body(content: Content) -> some View {
        content
            .overlay {
                DeleteAccountModal(
                    isPresented: $isPresented,
                    onConfirm: onConfirm,
                    onCancel: onCancel
                )
            }
    }
}

// MARK: - View Extension

extension View {
    func deleteAccountModal(
        isPresented: Binding<Bool>,
        onConfirm: @escaping () async -> Void,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            DeleteAccountModalModifier(
                isPresented: isPresented,
                onConfirm: onConfirm,
                onCancel: onCancel
            )
        )
    }
}
