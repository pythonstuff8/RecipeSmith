import SwiftUI
import Foundation

struct Recipe: Identifiable, Hashable, Codable {
    var id = UUID()
    var cuisine: String
    var title: String
    var description: String
    var imageDescription: String?
    var servings: String
    var servingSize: String?
    var prepTime: String
    var cookTime: String
    var totalTime: String
    var calorieCount: String
    var macros: RecipeMacros
    var ingredients: [String]
    var instructions: [String]
    var mealType: String
    var equipmentUsed: [String]
    var dietLabels: [String]
    var ingredientTypes: [String: [String]]?
    var imageName: String?
    var imageUrl: String?
    var isFromSaved: Bool = false

    enum CodingKeys: String, CodingKey {
        case id
        case cuisine = "cuisine"
        case title = "title"
        case description = "description"
        case imageDescription = "imgdesc"
        case servings = "servings"
        case servingSize = "serving_size"
        case prepTime = "prep"
        case cookTime = "cook"
        case totalTime = "total"
        case calorieCount = "cal"
        case macros = "macros"
        case ingredients = "ingredients"
        case instructions = "instructions"
        case mealType = "meal"
        case equipmentUsed = "equipment"
        case dietLabels = "diet"
        case ingredientTypes = "ingredient_types"
        case imageName = "imgname"
        case imageUrl = "imgurl"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        cuisine = try container.decode(String.self, forKey: .cuisine)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        prepTime = try container.decode(String.self, forKey: .prepTime)
        cookTime = try container.decode(String.self, forKey: .cookTime)
        totalTime = try container.decode(String.self, forKey: .totalTime)
        imageDescription = try container.decodeIfPresent(String.self, forKey: .imageDescription)
        servings = try container.decode(String.self, forKey: .servings)
        servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize)
        calorieCount = try container.decode(String.self, forKey: .calorieCount)
        ingredients = try container.decode([String].self, forKey: .ingredients)
        instructions = try container.decode([String].self, forKey: .instructions)
        mealType = try container.decode(String.self, forKey: .mealType)
        equipmentUsed = try container.decode([String].self, forKey: .equipmentUsed)
        dietLabels = try container.decode([String].self, forKey: .dietLabels)
        ingredientTypes = try? container.decodeIfPresent([String: [String]].self, forKey: .ingredientTypes)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        macros = try container.decode(RecipeMacros.self, forKey: .macros)
        isFromSaved = false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(cuisine, forKey: .cuisine)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(servingSize, forKey: .servingSize)
        try container.encodeIfPresent(imageDescription, forKey: .imageDescription)
        try container.encode(servings, forKey: .servings)
        try container.encode(prepTime, forKey: .prepTime)
        try container.encode(cookTime, forKey: .cookTime)
        try container.encode(totalTime, forKey: .totalTime)
        try container.encode(calorieCount, forKey: .calorieCount)
        try container.encode(macros, forKey: .macros)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(mealType, forKey: .mealType)
        try container.encode(equipmentUsed, forKey: .equipmentUsed)
        try container.encode(dietLabels, forKey: .dietLabels)
        try container.encodeIfPresent(ingredientTypes, forKey: .ingredientTypes)
        try container.encodeIfPresent(imageName, forKey: .imageName)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
    }
}

struct RecipeMacros: Hashable, Codable {
    let protein: String
    let carbohydrates: String
    let fat: String
    let fiber: String?
    let sugar: String?
    let sodium: String?
    let cholesterol: String?
    let saturatedFat: String?
    let transFat: String?
    let vitamins: [VitaminInfo]?
    let minerals: [MineralInfo]?
    
    enum CodingKeys: String, CodingKey {
        case protein
        case carbohydrates
        case fat
        case fiber
        case sugar
        case sodium
        case cholesterol
        case saturatedFat = "saturated_fat"
        case transFat = "trans_fat"
        case vitamins
        case minerals
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let proteinStr = try? container.decode(String.self, forKey: .protein) {
            protein = proteinStr
        } else if let proteinNum = try? container.decode(Int.self, forKey: .protein) {
            protein = "\(proteinNum)g"
        } else {
            protein = "0g"
        }
        
        if let carbsStr = try? container.decode(String.self, forKey: .carbohydrates) {
            carbohydrates = carbsStr
        } else if let carbsNum = try? container.decode(Int.self, forKey: .carbohydrates) {
            carbohydrates = "\(carbsNum)g"
        } else {
            carbohydrates = "0g"
        }
        
        if let fatStr = try? container.decode(String.self, forKey: .fat) {
            fat = fatStr
        } else if let fatNum = try? container.decode(Int.self, forKey: .fat) {
            fat = "\(fatNum)g"
        } else {
            fat = "0g"
        }
        
        fiber = try? container.decode(String.self, forKey: .fiber)
        sugar = try? container.decode(String.self, forKey: .sugar)
        sodium = try? container.decode(String.self, forKey: .sodium)
        cholesterol = try? container.decode(String.self, forKey: .cholesterol)
        saturatedFat = try? container.decode(String.self, forKey: .saturatedFat)
        transFat = try? container.decode(String.self, forKey: .transFat)
        vitamins = try? container.decode([VitaminInfo].self, forKey: .vitamins)
        minerals = try? container.decode([MineralInfo].self, forKey: .minerals)
    }
    
    init(protein: String, carbohydrates: String, fat: String) {
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = nil
        self.sugar = nil
        self.sodium = nil
        self.cholesterol = nil
        self.saturatedFat = nil
        self.transFat = nil
        self.vitamins = nil
        self.minerals = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(protein, forKey: .protein)
        try container.encode(carbohydrates, forKey: .carbohydrates)
        try container.encode(fat, forKey: .fat)
        try container.encodeIfPresent(fiber, forKey: .fiber)
        try container.encodeIfPresent(sugar, forKey: .sugar)
        try container.encodeIfPresent(sodium, forKey: .sodium)
        try container.encodeIfPresent(cholesterol, forKey: .cholesterol)
        try container.encodeIfPresent(saturatedFat, forKey: .saturatedFat)
        try container.encodeIfPresent(transFat, forKey: .transFat)
        try container.encodeIfPresent(vitamins, forKey: .vitamins)
        try container.encodeIfPresent(minerals, forKey: .minerals)
    }
}

struct VitaminInfo: Hashable, Codable {
    let name: String
    let amount: String
    let unit: String
}

struct MineralInfo: Hashable, Codable {
    let name: String
    let amount: String
    let unit: String
}

struct RecipeDisplayView: View {
    @State var recipe: Recipe
    @State private var showingBackAlert = false
    @State private var isSaved = false
    @State private var showingSaveConfirmation = false
    @State private var showingCopyConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var isFromSavedRecipes: Bool = false
    @State private var showingEditSheet = false
    @State private var pendingRecipe: Recipe?
    @State private var showingEditedContent = false
    @State private var isEditing = false
    @State private var pendingChanges: Recipe?
    @State private var showBloomingAnimation = false
    @State private var originalRecipe: Recipe?
    @State private var isUpdatingText = false   
    @State private var isLoadingEdit = false
    @EnvironmentObject private var navigationManager: NavigationManager
    @StateObject private var savedRecipesVM = SavedRecipesViewModel()
    
    private func copyRecipeToClipboard() {
        let recipeText = """
        \(recipe.title)
        
        Description:
        \(recipe.description)
        
        Servings: \(recipe.servings)
        Prep Time: \(recipe.prepTime)
        Cook Time: \(recipe.cookTime)
        Total Time: \(recipe.totalTime)
        
        Nutritional Information:
        Calories: \(recipe.calorieCount) per serving
        Protein: \(recipe.macros.protein)
        Carbs: \(recipe.macros.carbohydrates)
        Fat: \(recipe.macros.fat)
        
        Ingredients:
        \(recipe.ingredients.map { "• \($0)" }.joined(separator: "\n"))
        
        Instructions:
        \(recipe.instructions.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n"))
        
        Diet Labels: \(recipe.dietLabels.joined(separator: ", "))
        Equipment Needed: \(recipe.equipmentUsed.joined(separator: ", "))
        """
        
        UIPasteboard.general.string = recipeText
        showingCopyConfirmation = true
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                RecipeHeaderView(
                    recipe: recipe
                )
 
                RecipeContentView(
                    recipe: recipe,
                    showBloomingAnimation: showBloomingAnimation,
                    isUpdatingText: isUpdatingText
                )
                
                DietLabelsView(dietLabels: recipe.dietLabels)
                
                EquipmentView(equipment: recipe.equipmentUsed)
                
                IngredientsView(ingredients: recipe.ingredients)
                
                InstructionsView(instructions: recipe.instructions)
            }
            .padding(.vertical)
        }
        .overlay(alignment: .top) {
            let topInset = (UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?.safeAreaInsets.top) ?? 20

            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if recipe.isFromSaved {
                            navigationManager.goBack()
                        } else {
                            showingBackAlert = true
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                        .frame(width: 48, height: 48)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(PressableButtonStyle())

                Spacer()

                if isEditing {
                    HStack(spacing: 10) {
                        Button(action: {
                            withAnimation(.spring()) {
                                if let original = originalRecipe { recipe = original }
                                isEditing = false
                                originalRecipe = nil
                            }
                        }) {
                            Text("Revert")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .foregroundColor(.red)
                                .clipShape(Capsule())
                        }

                        Button(action: {
                            withAnimation(.spring()) {
                                isEditing = false
                                originalRecipe = nil
                                if recipe.isFromSaved { savedRecipesVM.saveRecipe(recipe) }
                            }
                        }) {
                            Text("Keep")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                } else {
                    RecipeActionsView(
                        showingCopyConfirmation: showingCopyConfirmation,
                        isFromSavedRecipes: isFromSavedRecipes,
                        onCopy: {
                            copyRecipeToClipboard()
                            showingCopyConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showingCopyConfirmation = false
                            }
                        },
                        onEdit: { showingEditSheet = true },
                        onDelete: { showingDeleteConfirmation = true },
                        onSave: {
                            var recipeToSave = recipe
                            recipeToSave.isFromSaved = true
                            savedRecipesVM.saveRecipe(recipeToSave)
                            withAnimation(.easeInOut) {
                                navigationManager.navigate(to: .savedRecipes)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, topInset - 4)
            .zIndex(10)
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 2)
        }
        .overlay(alignment: .topTrailing) {
             if showingEditedContent {
                 VStack(spacing: 16) {
                     Text("Review Changes")
                         .font(.headline)
                         .foregroundColor(.white)
                     
                     HStack(spacing: 16) {
                         Button("Keep Changes") {
                             withAnimation(.spring()) {
                                 if let _ = pendingRecipe {
                                     if recipe.isFromSaved {
                                         savedRecipesVM.saveRecipe(recipe)
                                     }
                                 }
                                 showingEditedContent = false
                                 pendingRecipe = nil
                                 originalRecipe = nil
                             }
                         }
                         .buttonStyle(.borderedProminent)
                         .tint(.green)
                         
                         Button("Revert") {
                             withAnimation(.spring()) {
                                 if let original = originalRecipe {
                                     recipe = original
                                 }
                                 showingEditedContent = false
                                 pendingRecipe = nil
                                 originalRecipe = nil
                             }
                         }
                         .buttonStyle(.bordered)
                         .tint(.red)
                     }
                 }
                 .padding()
                 .background(.ultraThinMaterial)
                 .cornerRadius(16)
                 .padding()
                 .transition(.move(edge: .top).combined(with: .opacity))
             }
         }
        .sheet(isPresented: $showingEditSheet) {
            RecipeEditView(recipe: $recipe) { updatedRecipe in
                originalRecipe = recipe
                recipe = updatedRecipe
                pendingRecipe = updatedRecipe
                showingEditedContent = true
            }
        }
        .overlay {
            if isLoadingEdit {
                LoadingOverlayView()
                    .transition(.opacity)
            }
        }
        .scrollContentBackground(.visible)
        .contentMargins(.zero)
        .background(Color(.systemBackground))
        .swipeBackGesture(action: {
            if isFromSavedRecipes {
                withAnimation(.easeInOut) {
                    navigationManager.goBack()
                }
            } else {
                showingBackAlert = true
            }
        })
        .alert("Go Back", isPresented: Binding(get: { showingBackAlert && !recipe.isFromSaved }, set: { showingBackAlert = $0 })) {
             Button("No", role: .cancel) {}
             Button("Yes", role: .destructive) {
                 if let imageName = recipe.imageName {
                     Task {
                         try? await APIService.shared.deleteFromS3(fileName: imageName)
                     }
                 }
                 navigationManager.navigateToRoot()
             }
         } message: {
             Text("Are you sure you want to go back? Your recipe will be lost.")
         }
        .onAppear {
            savedRecipesVM.loadSavedRecipes()
            isSaved = savedRecipesVM.savedRecipes.contains { $0.id == recipe.id }
            isFromSavedRecipes = recipe.isFromSaved

            if recipe.imageUrl == nil, let imageDescription = recipe.imageDescription {
                Task {
                    do {
                        let imageData = try await APIService.shared.generateImage(prompt: imageDescription)
                        if let imageBytes = Data(base64Encoded: imageData) {
                            let fileName = "\(recipe.title.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString.prefix(8)).png"
                            let imageUrl = try await APIService.shared.uploadToS3(imageData: imageBytes, fileName: fileName)
                            var updatedRecipe = recipe
                            updatedRecipe.imageName = fileName
                            updatedRecipe.imageUrl = imageUrl
                            await MainActor.run {
                                NavigationManager.shared.updateRecipe(updatedRecipe)
                            }
                        }
                    } catch {
                        print("Failed to generate/upload image: \(error)")
                    }
                }
            }
        }
        .alert("Delete Recipe", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                savedRecipesVM.deleteRecipes(at: IndexSet(integer: 
                    savedRecipesVM.savedRecipes.firstIndex(where: { $0.id == recipe.id }) ?? 0
                ))
                navigationManager.goBack()
            }
        } message: {
            Text("Are you sure you want to delete this recipe?")
        }
        .onAppear {
            savedRecipesVM.loadSavedRecipes()
            isFromSavedRecipes = recipe.isFromSaved
        }
        .onChange(of: navigationManager.currentDestination) { newDestination in
            if case .recipeDisplay(let updatedRecipe) = newDestination, updatedRecipe.id == recipe.id {
                recipe = updatedRecipe
            }
        }
    }
}

struct RecipeHeaderView: View {
    let recipe: Recipe
    
    var body: some View {
        let topInset = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top) ?? 20

         AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
             switch phase {
             case .empty:
                 ProgressView()
             case .success(let image):
                 image
                     .resizable()
                     .aspectRatio(contentMode: .fill)
                     .frame(maxWidth: .infinity)
                     .frame(height: 300)
                     .clipped()
             case .failure(_):
                 Image(systemName: "photo")
                     .resizable()
                     .aspectRatio(contentMode: .fit)
             @unknown default:
                 EmptyView()
             }
         }
         .frame(maxWidth: .infinity)
         .frame(height: 300)
         .padding(.top, topInset + 16)
         .cornerRadius(12)
     }
 }

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct NutritionalInfoView: View {
    let recipe: Recipe
    
    var body: some View {
        GroupBox(label: Text("Nutritional Information").fontWeight(.semibold)) {
            VStack(spacing: 12) {
                InfoRow(title: "Calories", value: "\(recipe.calorieCount) per serving")
                InfoRow(title: "Protein", value: recipe.macros.protein)
                InfoRow(title: "Carbs", value: recipe.macros.carbohydrates)
                InfoRow(title: "Fat", value: recipe.macros.fat)
            }
        }
    }
}

struct RecipeDetailsView: View {
    let recipe: Recipe
    
    var body: some View {
        GroupBox(label: Text("Time & Basic Info").fontWeight(.semibold)) {
            VStack(spacing: 12) {
                InfoRow(title: "Prep Time", value: recipe.prepTime)
                InfoRow(title: "Cook Time", value: recipe.cookTime)
                InfoRow(title: "Total Time", value: recipe.totalTime)
                InfoRow(title: "Cuisine", value: recipe.cuisine)
                InfoRow(title: "Servings", value: recipe.servings)
                InfoRow(title: "Course", value: recipe.mealType)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for placement in result.placements {
            let x = bounds.origin.x + placement.point.x
            let y = bounds.origin.y + placement.point.y
            placement.subview.place(at: CGPoint(x: x, y: y), proposal: placement.proposal)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var placements: [(subview: LayoutSubview, point: CGPoint, proposal: ProposedViewSize)] = []
        
        init(in width: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if x + subviewSize.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                placements.append((subview, CGPoint(x: x, y: y), ProposedViewSize(subviewSize)))
                rowHeight = max(rowHeight, subviewSize.height)
                x += subviewSize.width + spacing
                size.width = max(size.width, x)
            }
            
            size.height = y + rowHeight
        }
    }
}

struct RecipeDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRecipe = try! JSONDecoder().decode(Recipe.self, from: """
            {
                "cuisine": "Italian",
                "title": "Sample Recipe",
                "description": "A delicious sample recipe",
                "imgdesc": "Sample image description",
                "servings": "4",
                "prep": "15 mins",
                "cook": "30 mins",
                "total": "45 mins",
                "cal": "450",
                "macros": {
                    "protein": "20g",
                    "carbohydrates": "45g",
                    "fat": "15g"
                },
                "ingredients": ["Ingredient 1", "Ingredient 2"],
                "instructions": ["Step 1", "Step 2"],
                "meal": "Dinner",
                "equipment": ["Oven", "Pan"],
                "diet": ["Vegetarian"]
            }
            """.data(using: .utf8)!)
        
        return RecipeDisplayView(recipe: sampleRecipe)
            .environmentObject(NavigationManager())
    }
}

struct BloomingTextModifier: ViewModifier {
    let shouldAnimate: Bool
    @State private var animate = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(shouldAnimate && animate ? 1.05 : 1.0)
            .blur(radius: shouldAnimate && animate ? 0.5 : 0)
            .animation(
                shouldAnimate ? 
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true) : 
                    .default,
                value: animate
            )
            .onAppear {
                if shouldAnimate {
                    animate = true
                }
            }
            .onChange(of: shouldAnimate) { newValue in
                animate = newValue
            }
    }
}

struct LoadingOverlayView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Updating Recipe...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
        .ignoresSafeArea()
    }
}

struct BubbleButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: isPressed ? 2 : 8, x: 0, y: isPressed ? 1 : 4)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecipeActionsView: View {
    let showingCopyConfirmation: Bool
    let isFromSavedRecipes: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSave: () -> Void
     
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onCopy) {
                Image(systemName: showingCopyConfirmation ? "checkmark" : "doc.on.doc")
                    .imageScale(.large)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(PressableButtonStyle())
            
            if isFromSavedRecipes {
                Button(action: onEdit) {
                    Image(systemName: "wand.and.stars")
                        .imageScale(.large)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(PressableButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .imageScale(.large)
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(PressableButtonStyle())
            } else {
                Button(action: onSave) {
                    Image(systemName: "bookmark")
                        .imageScale(.large)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding()
    }
 }

struct RecipeContentView: View {
    let recipe: Recipe
    let showBloomingAnimation: Bool
    let isUpdatingText: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(recipe.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .modifier(BloomingTextModifier(shouldAnimate: showBloomingAnimation))
                .opacity(isUpdatingText ? 0.5 : 1.0)

            Text(recipe.description)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .modifier(BloomingTextModifier(shouldAnimate: showBloomingAnimation))
                .opacity(isUpdatingText ? 0.5 : 1.0)
            
            RecipeDetailsView(recipe: recipe)
                .padding(.horizontal)
            
            NutritionalInfoView(recipe: recipe)
                .padding(.horizontal)
        }
    }
}

struct DietLabelsView: View {
    let dietLabels: [String]
    
    var body: some View {
        if !dietLabels.isEmpty {
            GroupBox(label: Text("Diet Labels").fontWeight(.semibold)) {
                FlowLayout(spacing: 8) {
                    ForEach(dietLabels, id: \.self) { label in
                        Text(label.capitalized)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct EquipmentView: View {
    let equipment: [String]
    
    var body: some View {
        if !equipment.isEmpty {
            GroupBox(label: Text("Equipment Needed").fontWeight(.semibold)) {
                FlowLayout(spacing: 8) {
                    ForEach(equipment, id: \.self) { equipment in
                        Text(equipment.capitalized)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct IngredientsView: View {
    let ingredients: [String]
    
    var body: some View {
        if ingredients.isEmpty {
            EmptyView()
        } else {
            GroupBox(label: Text("Ingredients").fontWeight(.semibold)) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(ingredients, id: \.self) { ingredient in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text(ingredient)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal)
        }
    }
}

struct InstructionsView: View {
    let instructions: [String]
    
    var body: some View {
        if instructions.isEmpty {
            EmptyView()
        } else {
            GroupBox(label: Text("Instructions").fontWeight(.semibold)) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 32, height: 32)
                                Text("\(index + 1)")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                                    .bold()
                            }
                            
                            Text(instruction.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression))
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal)
        }
    }
}
