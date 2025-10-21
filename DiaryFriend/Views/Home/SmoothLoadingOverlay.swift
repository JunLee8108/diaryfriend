//
//  SmoothLoadingOverlay.swift
//  DiaryFriend
//
//  간단하고 빠른 로딩 오버레이
//

import SwiftUI

struct SmoothLoadingOverlay: View {
    let isLoading: Bool
    
    var body: some View {
        if isLoading {
            ZStack {
                // 배경 오버레이
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                
                // 로딩 인디케이터
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                        .tint(.primary)
                    
                    Text("Loading...")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                )
            }
            .transition(.opacity)
            .animation(.easeOut(duration: 0.2), value: isLoading)
        }
    }
}

// MARK: - ViewModifier

struct SmoothLoadingModifier: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay {
                SmoothLoadingOverlay(isLoading: isLoading)
            }
    }
}

// MARK: - View Extension

extension View {
    func smoothLoading(_ isLoading: Bool) -> some View {
        self.modifier(
            SmoothLoadingModifier(isLoading: isLoading)
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var isLoading = false
        
        var body: some View {
            VStack(spacing: 30) {
                Text("Loading Overlay Test")
                    .font(.title)
                
                Toggle("Loading", isOn: $isLoading)
                    .toggleStyle(.switch)
                    .padding(.horizontal, 40)
                
                Button("Toggle Loading") {
                    isLoading.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
            .smoothLoading(isLoading)
        }
    }
    
    return PreviewWrapper()
}
