import SwiftUI

struct RecipeEditView: View {
    @Binding var recipe: Recipe
    @State private var editPrompt: String = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    let onUpdate: ((Recipe) -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What changes would you like to make?")
                        .font(.headline)
                    
                    TextEditor(text: $editPrompt)
                        .frame(height: 120)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                Button(action: submitChanges) {
                    Text("Submit Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(editPrompt.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(editPrompt.isEmpty)
                .padding(.horizontal)
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                Text("Updating Recipe...")
                                    .foregroundColor(.white)
                            }
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                        }
                }
            }
        }
    }
    
    private func submitChanges() {
        isLoading = true
        
        Task {
            do {
                let prompt = """
                Update this recipe according to the following changes: \(editPrompt)
                
                Current Recipe:
                Title: \(recipe.title)
                Description: \(recipe.description)
                
                Maintain the JSON format and update ONLY the text fields without changing the image.
                """
                
                let updatedRecipe = try await APIService.shared.generateRecipeData(prompt: prompt)
                
                await MainActor.run {
                    var finalRecipe = updatedRecipe
                    finalRecipe.id = recipe.id 
                    finalRecipe.imageUrl = recipe.imageUrl 
                    finalRecipe.imageName = recipe.imageName
                    finalRecipe.isFromSaved = recipe.isFromSaved
                    
                    onUpdate?(finalRecipe) 
                    isLoading = false
                    dismiss()
                }
            } catch {
                print("Failed to update recipe:", error)
                isLoading = false
            }
        }
    }
}
