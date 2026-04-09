import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.dismiss) var dismiss
    
    let currentLanguage: Language
    let onSelect: (Language) async throws -> Void
    @Binding var isLoadingBinding: Bool  // ⭐ 부모에게 로딩 상태 전달
    
    @State private var selectedLanguage: Language
    @State private var errorMessage: String?
    @State private var showError = false
    
    // ⭐ 다국어
    @Localized(.language_select_title) var title
    @Localized(.language_english_desc) var englishDesc
    @Localized(.language_korean_desc) var koreanDesc
    @Localized(.error_title) var errorTitle
    @Localized(.common_ok) var okButton
    
    init(currentLanguage: Language,
         isLoadingBinding: Binding<Bool>,  // ⭐ 추가
         onSelect: @escaping (Language) async throws -> Void) {
        self.currentLanguage = currentLanguage
        self._isLoadingBinding = isLoadingBinding
        self.onSelect = onSelect
        self._selectedLanguage = State(initialValue: currentLanguage)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // ⭐ Korean 필터 제거!
                ForEach(Language.allCases, id: \.self) { language in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(language.displayName)
                                .font(.body)
                            
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
                    .disabled(isLoadingBinding)  // ⭐ binding 사용
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .alert(errorTitle, isPresented: $showError) {
                Button(okButton) { }
            } message: {
                Text(errorMessage ?? "Failed to update language")
            }
        }
    }
    
    private func languageDescription(for language: Language) -> String {
        switch language {
        case .english:
            return englishDesc
        case .korean:
            return koreanDesc
        }
    }
    
    private func selectLanguage(_ language: Language) {
        guard language != currentLanguage else {
            dismiss()
            return
        }
        
        selectedLanguage = language
        isLoadingBinding = true  // ⭐ 부모에게 로딩 시작 알림
        
        Task {
            do {
                try await onSelect(language)
                
                // ⭐ LocalizationManager 즉시 업데이트
                await MainActor.run {
                    let appLanguage: AppLanguage = (language == .korean) ? .korean : .english
                    LocalizationManager.shared.setLanguage(appLanguage)
                    dismiss()
                }
                
                // ⭐ 0.5초 대기 후 dismiss
                try await Task.sleep(nanoseconds: 500_000_000)
                
                await MainActor.run {
                    isLoadingBinding = false  // ⭐ 로딩 종료
                }
            } catch {
                await MainActor.run {
                    selectedLanguage = currentLanguage
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoadingBinding = false  // ⭐ 로딩 종료
                }
            }
        }
    }
}
