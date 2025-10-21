//
//  SocialLoginSection.swift
//  DiaryFriend
//

import SwiftUI

struct SocialLoginSection: View {
    @EnvironmentObject var authService: AuthService
    @Binding var errorMessage: String
    @Binding var showError: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Apple Sign In 버튼 (상단 배치 - Apple 가이드라인 권장)
            appleSignInButton
            
            // Google Sign In 버튼
            googleSignInButton
        }
    }
    
    // MARK: - Apple Sign In Button
    private var appleSignInButton: some View {
        Button(action: handleAppleSignIn) {
            HStack(spacing: 12) {
                // 고정 너비 컨테이너로 아이콘 정렬
                Image(systemName: "apple.logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                    .frame(width: 20) // 고정 너비 추가
                
                Text("Continue with Apple")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 30)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .disabled(authService.isLoading)
        .opacity(authService.isLoading ? 0.6 : 1.0)
    }
    
    // MARK: - Google Sign In Button
    private var googleSignInButton: some View {
        Button(action: handleGoogleSignIn) {
            HStack(spacing: 12) {
                // 고정 너비 컨테이너로 아이콘 정렬
                Image("google-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .frame(width: 20) // 고정 너비 추가
                
                Text("Continue with Google")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 30)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .disabled(authService.isLoading)
        .opacity(authService.isLoading ? 0.6 : 1.0)
    }
    
    // MARK: - Actions
    
    private func handleAppleSignIn() {
        Task {
            do {
                try await authService.signInWithApple()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func handleGoogleSignIn() {
        Task {
            do {
                try await authService.signInWithGoogle()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SocialLoginSection(
        errorMessage: .constant(""),
        showError: .constant(false)
    )
    .environmentObject(AuthService())
}
