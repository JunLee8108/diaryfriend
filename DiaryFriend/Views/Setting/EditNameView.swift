//
//  EditNameView.swift
//  DiaryFriend
//
//  Display Name 편집 Sheet
//

import SwiftUI

struct EditNameView: View {
    @Environment(\.dismiss) var dismiss
    
    let currentName: String
    let onSave: (String) async throws -> Void
    
    @State private var newName: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // ⭐ 다국어 적용
    @Localized(.edit_name_title) var title
    @Localized(.edit_name_display_name) var displayNameLabel
    @Localized(.edit_name_placeholder) var placeholder
    @Localized(.edit_name_save) var saveButton
    @Localized(.edit_name_saving) var savingMessage
    @Localized(.edit_name_too_long) var tooLongError
    @Localized(.edit_name_cannot_empty) var cannotEmptyError
    @Localized(.error_title) var errorTitle
    @Localized(.common_ok) var okButton
    
    // 유효성 검사
    private var isNameValid: Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 30
    }
    
    private var characterCount: Int {
        newName.count
    }
    
    private var characterCountColor: Color {
        if characterCount > 30 {
            return .red
        } else if characterCount > 25 {
            return .orange
        } else {
            return .secondary
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Text Field Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayNameLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField(placeholder, text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isLoading)
                    
                    // Character Count
                    HStack {
                        if characterCount > 30 {
                            Text(tooLongError)
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !newName.isEmpty {
                            Text(cannotEmptyError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        Text("\(characterCount)/30")
                            .font(.caption)
                            .foregroundColor(characterCountColor)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Save Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(saveButton) {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isNameValid || isLoading || newName.trimmingCharacters(in: .whitespacesAndNewlines) == currentName)
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView(savingMessage)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .alert(errorTitle, isPresented: $showError) {
                Button(okButton) { }
            } message: {
                Text(errorMessage ?? LocalizationManager.shared.localized(.edit_name_update_failed))
            }
            .onAppear {
                newName = currentName
            }
        }
    }
    
    private func saveChanges() {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard isNameValid else { return }
        
        isLoading = true
        
        Task {
            do {
                try await onSave(trimmedName)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    EditNameView(
        currentName: "John Doe",
        onSave: { _ in
            // Preview save action
        }
    )
    .environmentObject(LocalizationManager.shared)
}
