//
//  EditNameView.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/1/25.
//

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
                    Text("Display Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your name", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isLoading)
                    
                    // Character Count
                    HStack {
                        if characterCount > 30 {
                            Text("Name is too long")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !newName.isEmpty {
                            Text("Name cannot be empty")
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
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Save Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
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
                    ProgressView("Saving...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to update name")
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
}
