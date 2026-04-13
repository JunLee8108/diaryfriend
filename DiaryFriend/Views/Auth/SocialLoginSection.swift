//
//  SocialLoginSection.swift
//  DiaryFriend
//

import SwiftUI

struct SocialLoginSection: View {
    @EnvironmentObject var authService: AuthService
    @Binding var errorMessage: String
    @Binding var showError: Bool

    @Localized(.login_apple) var appleText
    @Localized(.login_google) var googleText

    var body: some View {
        VStack(spacing: 14) {
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
                Image(systemName: "apple.logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .frame(width: 20)

                Text(appleText)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .background(Color.modernSurfacePrimary)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
        )
        .padding(.horizontal, 30)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .disabled(authService.isLoading)
        .opacity(authService.isLoading ? 0.6 : 1.0)
    }

    // MARK: - Google Sign In Button
    private var googleSignInButton: some View {
        Button(action: handleGoogleSignIn) {
            HStack(spacing: 12) {
                Image("google-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .frame(width: 20)

                Text(googleText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .background(Color.modernSurfacePrimary)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
        )
        .padding(.horizontal, 30)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .disabled(authService.isLoading)
        .opacity(authService.isLoading ? 0.6 : 1.0)
    }

    // MARK: - Actions

    private func handleAppleSignIn() {
        Task {
            do {
                try await authService.signInWithApple()
            } catch AuthError.userCancelled {
                // User cancelled sign-in, no error to show
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
            } catch AuthError.userCancelled {
                // User cancelled sign-in, no error to show
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
