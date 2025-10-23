//
//  LoginView.swift
//  DiaryFriend
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showHelp = false  // Help Sheet State
    
    @Localized(.login_subtitle) var loginSubtitle
    @Localized(.login_why_signin) var whySignInText
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.modernBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 50) {
                    Spacer()
                    
                    logoSection
                    
                    SocialLoginSection(
                        errorMessage: $errorMessage,
                        showError: $showError
                    )
                    .environmentObject(authService)
                    
                    helpLinkSection
                    
                    Spacer()
                    Spacer()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
        }
    }
    
    private var logoSection: some View {
        VStack(spacing: 10) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            
            Text("DiaryFriend")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Text(loginSubtitle)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }
    
    private var helpLinkSection: some View {
        Button(action: {
            showHelp = true
        }) {
            Text(whySignInText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .underline()
        }
        .padding(.top, -20)
    }
}
