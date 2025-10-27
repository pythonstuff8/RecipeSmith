import SwiftUI
import Foundation
import Combine

class SavedRecipesViewModel: ObservableObject {
    @Published var savedRecipes: [Recipe] = []
    private let savedRecipesKey = "SavedRecipes"
    
    init() {
        loadSavedRecipes()
    }
    
    func loadSavedRecipes() {
        if let data = UserDefaults.standard.data(forKey: savedRecipesKey) {
            do {
                savedRecipes = try JSONDecoder().decode([Recipe].self, from: data)
            } catch {
                print("Error loading saved recipes: \(error)")
            }
        }
    }
    
    func saveRecipe(_ recipe: Recipe) {
        if let existingIndex = savedRecipes.firstIndex(where: { $0.id == recipe.id }) {
            savedRecipes[existingIndex] = recipe
        } else {
            var updatedRecipe = recipe
            updatedRecipe.isFromSaved = true
            savedRecipes.append(updatedRecipe)
        }
        saveToDisk()
    }
    
    func deleteRecipes(at offsets: IndexSet) {
        savedRecipes.remove(atOffsets: offsets)
        saveToDisk()
    }
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(savedRecipes)
            UserDefaults.standard.set(data, forKey: savedRecipesKey)
        } catch {
            print("Error saving recipes: \(error)")
        }
    }
}

struct SavedRecipesView: View {
    @StateObject private var viewModel = SavedRecipesViewModel()
    @EnvironmentObject private var navigationManager: NavigationManager
    @State private var isEditing = false
    @State private var selection = Set<UUID>()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.savedRecipes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No Saved Recipes")
                            .font(.title2)
                        Text("Save recipes to access them here")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(selection: $selection) {
                        ForEach(viewModel.savedRecipes) { recipe in
                            SavedRecipeRow(recipe: recipe)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isEditing {
                                        if selection.contains(recipe.id) {
                                            selection.remove(recipe.id)
                                        } else {
                                            selection.insert(recipe.id)
                                        }
                                    } else {
                                        var savedRecipe = recipe
                                        savedRecipe.isFromSaved = true
                                        withAnimation(.easeInOut) {
                                            navigationManager.navigate(to: .recipeDisplay(savedRecipe))
                                        }
                                    }
                                }
                        }
                        .onDelete(perform: isEditing ? { indexSet in
                            withAnimation {
                                viewModel.deleteRecipes(at: indexSet)
                            }
                        } : nil)
                    }
                    .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            if isEditing {
                                Button("Delete") {
                                    let indicesToDelete = viewModel.savedRecipes.enumerated()
                                        .filter { selection.contains($0.element.id) }
                                        .map { $0.offset }
                                    viewModel.deleteRecipes(at: IndexSet(indicesToDelete))
                                    selection.removeAll()
                                }
                                .foregroundColor(.red)
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(isEditing ? "Done" : "Edit") {
                                withAnimation {
                                    isEditing.toggle()
                                    if !isEditing { selection.removeAll() }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved Recipes")
        }
        .scrollContentBackground(.visible)
        .contentMargins(.zero)
        .background(Color(.systemBackground))
    }
}

struct SavedRecipeRow: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(spacing: 12) {
            if let imageUrl = recipe.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "photo")
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                Text("\(recipe.cuisine) • \(recipe.mealType)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}