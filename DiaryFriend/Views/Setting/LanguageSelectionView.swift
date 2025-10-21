//
//  LanguageSelectionView.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/1/25.
//

//
//  LanguageSelectionView.swift
//  DiaryFriend
//
//  Language 선택 Sheet
//

import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.dismiss) var dismiss
    
    let currentLanguage: Language
    let onSelect: (Language) async throws -> Void
    
    @State private var selectedLanguage: Language
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    init(currentLanguage: Language, onSelect: @escaping (Language) async throws -> Void) {
        self.currentLanguage = currentLanguage
        self.onSelect = onSelect
        self._selectedLanguage = State(initialValue: currentLanguage)
    }
    
    var body: some View {
        NavigationStack {
            List {
//                ForEach(Language.allCases, id: \.self) { language in
//                    HStack {
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text(language.displayName)
//                                .font(.body)
//                            
//                            // 언어별 설명 추가
//                            Text(languageDescription(for: language))
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                        
//                        Spacer()
//                        
//                        if selectedLanguage == language {
//                            Image(systemName: "checkmark")
//                                .foregroundColor(.blue)
//                                .fontWeight(.semibold)
//                        }
//                    }
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        selectLanguage(language)
//                    }
//                    .disabled(isLoading)
//                }
                ForEach(Language.allCases.filter { $0 != .korean }, id: \.self) { language in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(language.displayName)
                                .font(.body)
                            
                            // 언어별 설명 추가
                            Text(languageDescription(for: language))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectLanguage(language)
                    }
                    .disabled(isLoading)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Updating...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to update language")
            }
        }
    }
    
    private func languageDescription(for language: Language) -> String {
        switch language {
        case .english:
            return "Use English for all app content"
        case .korean:
            return "모든 앱 콘텐츠를 한국어로 표시"
        }
    }
    
    private func selectLanguage(_ language: Language) {
        // 같은 언어를 선택한 경우 무시
        guard language != currentLanguage else {
            dismiss()
            return
        }
        
        selectedLanguage = language
        isLoading = true
        
        Task {
            do {
                try await onSelect(language)
                
                await MainActor.run {
                    // 성공 시 자동으로 닫기
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    // 에러 발생 시 원래 언어로 되돌리기
                    selectedLanguage = currentLanguage
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    LanguageSelectionView(
        currentLanguage: .english,
        onSelect: { _ in
            // Preview action
        }
    )
}
