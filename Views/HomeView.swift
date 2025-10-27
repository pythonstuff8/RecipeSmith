import SwiftUI
import Combine
import Foundation

typealias AppIngredient = Ingredient  

struct Ingredient: Identifiable, Hashable, Codable {
    public let id: UUID
    public var text: String
    public var detail: IngredientDetail?

    public init(id: UUID = UUID(), text: String = "", detail: IngredientDetail? = nil) {
        self.id = id
        self.text = text
        self.detail = detail
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case text
        case detail
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        detail = try container.decodeIfPresent(IngredientDetail.self, forKey: .detail)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(detail, forKey: .detail)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        lhs.id == rhs.id
    }
}

struct IngredientDetail: Identifiable, Hashable, Codable {
    public let id: Int
    public let name: String
    public let calories: Double
    public let protein: Double
    public let carbs: Double
    public let fat: Double
    public let servingSize: Double
    public let servingSizeUnit: String
    public var imageUrl: String?
    
    public init(id: Int,
                name: String,
                calories: Double,
                protein: Double,
                carbs: Double,
                fat: Double,
                servingSize: Double,
                servingSizeUnit: String,
                imageUrl: String? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.servingSizeUnit = servingSizeUnit
        self.imageUrl = imageUrl
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case calories
        case protein
        case carbs
        case fat
        case servingSize
        case servingSizeUnit
        case imageUrl
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: IngredientDetail, rhs: IngredientDetail) -> Bool {
        lhs.id == rhs.id
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("RecipeSmith")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                Text("Add your ingredients")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    ForEach($viewModel.ingredients.indices, id: \.self) { index in
                        let binding = $viewModel.ingredients[index]
                        let ingredient = binding.wrappedValue
                        HStack {
                            if let detail = ingredient.detail {
                                HStack {
                                    Text(detail.name)
                                        .lineLimit(1)
                                    
                                    Text("\(Int(detail.calories)) cal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        var updated = ingredient
                                        updated.detail = nil
                                        updated.text = ""
                                        binding.wrappedValue = updated
                                        viewModel.saveState()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            } else {
                                Button(action: {
                                    viewModel.showIngredientSearch(forIndex: index)
                                }) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.gray)
                                        Text(ingredient.text.isEmpty ? "Search ingredients..." : ingredient.text)
                                            .foregroundColor(ingredient.text.isEmpty ? .gray : .primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            
                            Button(action: {
                                viewModel.removeIngredient(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button(action: viewModel.addIngredient) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding()
                
                VStack(spacing: 8) {
                    Text("Only These Ingredients?")
                        .font(.headline)

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill((viewModel.onlyTheseIngredients ? Color.green : Color.red).opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.onlyTheseIngredients ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: (viewModel.onlyTheseIngredients ? Color.green : Color.red).opacity(0.15), radius: viewModel.onlyTheseIngredients ? 6 : 0, x: 0, y: 2)
                            .scaleEffect(viewModel.onlyTheseIngredients ? 1.02 : 1.0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.onlyTheseIngredients)

                        Toggle("", isOn: $viewModel.onlyTheseIngredients)
                            .labelsHidden()
                            .tint(viewModel.onlyTheseIngredients ? .green : .red)
                            .padding(.horizontal)
                    }
                    .frame(height: 44)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.onlyTheseIngredients.toggle()
                        }
                        let generator = UIImpactFeedbackGenerator(style: .soft)
                        generator.impactOccurred()
                    }
                }
                
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            navigationManager.navigate(to: .extraDetails(source: .home))
                        }
                    }) {
                        Label("Customize", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .buttonStyle(PressableButtonStyle())
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            navigationManager.navigate(to: .popularDishes)
                        }
                    }) {
                        Label("Popular Dishes", systemImage: "star.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .buttonStyle(PressableButtonStyle())
                    
                    Button(action: viewModel.generateRecipe) {
                        Label("Generate Recipe", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding()
            }
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.visible)
        .contentMargins(.zero)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showingIngredientSearch) {
            if let index = viewModel.selectedIngredientIndex, index < viewModel.ingredients.count {
                IngredientSearchView(selectedIngredient: $viewModel.ingredients[index])
            } else {
                EmptyView()
            }
        }
        .onDisappear {
            viewModel.saveStateOnDisappear()
        }
        .onAppear {
            viewModel.loadSavedState()
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

class HomeViewModel: ObservableObject {
    @Published fileprivate var ingredients: [AppIngredient] = []
    @Published var onlyTheseIngredients = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showingIngredientSearch = false
    @Published var selectedIngredientIndex: Int?
    
    private let ingredientsKey = "SavedIngredients"
    private let onlyIngredientsKey = "OnlyTheseIngredients"
    
    init() {
        loadSavedState()
    }
    
    func loadSavedState() {
        onlyTheseIngredients = UserDefaults.standard.bool(forKey: onlyIngredientsKey)
        
        if let savedData = UserDefaults.standard.data(forKey: ingredientsKey) {
            do {
                ingredients = try JSONDecoder().decode([AppIngredient].self, from: savedData)
            } catch {
                print("Error loading ingredients: \(error)")
                createDefaultIngredients()
            }
        } else {
            createDefaultIngredients()
        }
    }
    
    private func createDefaultIngredients() {
        ingredients = [Ingredient()]
        saveState()
    }
    
    func saveState() {
        UserDefaults.standard.set(onlyTheseIngredients, forKey: onlyIngredientsKey)
        
        do {
            let encodedData = try JSONEncoder().encode(ingredients)
            UserDefaults.standard.set(encodedData, forKey: ingredientsKey)
            UserDefaults.standard.synchronize() 
        } catch {
            print("Error saving ingredients: \(error)")
        }
    }
    
    func saveStateOnDisappear() {
        saveState()
    }
    
    func addIngredient() {
        ingredients.append(AppIngredient())
        saveState()
    }
    
    func removeIngredient(at index: Int) {
        guard index >= 0 && index < ingredients.count else { return }
        ingredients.remove(at: index)
        saveState()
    }
    
    func showIngredientSearch(forIndex index: Int) {
        selectedIngredientIndex = index
        showingIngredientSearch = true
    }
    
    func generateRecipe() {
        let validIngredients = ingredients.compactMap { ingredient -> String? in
            let name = ingredient.detail?.name ?? ingredient.text
            return name.isEmpty ? nil : name
        }
        
        if validIngredients.isEmpty {
            showError = true
            errorMessage = "Please add at least one ingredient"
            return
        }
        
        Task {
            do {
                NavigationManager.shared.navigate(to: .loading)
                
                var extraDetails = UserDefaults.standard.dictionary(forKey: "ExtraDetailsSelections") ?? [:]
                extraDetails["strict_ingredients"] = onlyTheseIngredients
                
                let recipe = try await RecipeService.shared.generateRecipe(
                    ingredients: validIngredients,
                    allowOtherIngredients: !onlyTheseIngredients,
                    extraDetails: extraDetails
                )
                
                await MainActor.run {
                    NavigationManager.shared.navigate(to: .recipeDisplay(recipe))
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = "Failed to generate recipe: \(error.localizedDescription)"
                    NavigationManager.shared.goBack()
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(NavigationManager())
    }
}
