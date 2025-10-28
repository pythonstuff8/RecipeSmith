import SwiftUI

struct NutritionAnalyticsView: View {
    @StateObject private var savedVM = SavedRecipesViewModel()
    private let nutritionService = NutritionService.shared
    @EnvironmentObject private var navigationManager: NavigationManager
    @State private var selectedTab: Int = 2
    @State private var selectedRecipe: Recipe?
    @State private var dietSet: Set<String>
    @State private var nutritionData: NutritionData?
    @State private var healthInsights: [HealthInsight] = []
    @State private var nutritionTrends: [NutritionTrend] = []
    
    @State private var isUpdating: Bool = false
    @State private var showCheckmark: Bool = false
    @State private var updatingRecipe: Recipe? = nil
    @State private var appliedRecommendations: Set<String> = []
    
    init(initialRecipe: Recipe? = nil) {
        _selectedRecipe = State(initialValue: initialRecipe)
        let savedDietRecipes = UserDefaults.standard.stringArray(forKey: "DietRecipes") ?? []
        _dietSet = State(initialValue: Set(savedDietRecipes))
    }
        

    private var filteredHealthInsights: [HealthInsight] {
        healthInsights.filter { insight in
            guard let recommendation = insight.recommendation else { return true }
            return !appliedRecommendations.contains(recommendation)
        }
    }
    
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationView {
                if selectedRecipe != nil {
                    DetailedNutritionView(
                        recipe: selectedRecipe!,
                        nutritionData: nutritionData,
                        healthInsights: filteredHealthInsights,
                        
                        nutritionTrends: nutritionTrends,
                        isUpdating: isUpdating,
                        showCheckmark: showCheckmark,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedRecipe = nil
                                nutritionData = nil
                                healthInsights = []
                                
                                nutritionTrends = []
                                appliedRecommendations = []
                            }
                        },
                        onApplyRecommendation: { rec in applyRecommendationToRecipe(rec) }
                    )
                } else {
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Nutrition Analytics")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Spacer()
                                Button("Refresh") { 
                                    savedVM.loadSavedRecipes()
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                            
                            Divider()
                                .padding(.vertical, 16)
                            
                            Text("Saved Recipes")
                                .font(.headline)
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(savedVM.savedRecipes) { recipe in
                                    RecipeCard(
                                        recipe: recipe,
                                        isSelected: false,
                                        isInDiet: dietSet.contains(recipe.id.uuidString),
                                        onTap: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                selectedRecipe = recipe
                                                updateNutritionData(for: recipe)
                                            }
                                        },
                                        onAddToDiet: { 
                                            dietSet.insert(recipe.id.uuidString)
                                            UserDefaults.standard.set(Array(dietSet), forKey: "DietRecipes")
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .navigationViewStyle(.stack)
            .onAppear { 
                savedVM.loadSavedRecipes()
                selectedTab = 2
            }
            .padding(.bottom, 60) 
            
            BottomTabBar(selectedTab: $selectedTab)
                .environmentObject(navigationManager)
                .background(.ultraThinMaterial)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private func updateNutritionData(for recipe: Recipe) {
        nutritionData = nutritionService.calculateNutritionData(from: recipe)
        healthInsights = nutritionService.generateHealthInsights(for: nutritionData!)
        nutritionTrends = nutritionService.analyzeNutritionTrends(from: savedVM.savedRecipes)
        
    }
    
    private func applyRecommendationToRecipe(_ recommendation: String) {
        guard let recipe = selectedRecipe else { return }
        
        isUpdating = true
        showCheckmark = false
        updatingRecipe = recipe
        
        Task {
            do {
                let prompt = """
                Update the following recipe based on this health recommendation: \(recommendation)
                
                Current Recipe:
                Title: \(recipe.title)
                Description: \(recipe.description)
                Ingredients: \(recipe.ingredients.joined(separator: ", "))
                Instructions: \(recipe.instructions.joined(separator: "\n"))
                
                The updated recipe should incorporate the recommendation while maintaining the recipe's character.
                Return the recipe in the same JSON format with all nutritional information including fiber, sugar, sodium, cholesterol, saturated_fat, trans_fat, vitamins, and minerals.
                """
                
                let updatedRecipe = try await APIService.shared.generateRecipeData(prompt: prompt)
                
                var finalRecipe = updatedRecipe
                finalRecipe.id = recipe.id
                finalRecipe.imageUrl = recipe.imageUrl
                finalRecipe.imageName = recipe.imageName
                finalRecipe.isFromSaved = recipe.isFromSaved
                
                savedVM.saveRecipe(finalRecipe)
                
                await MainActor.run {
                    selectedRecipe = finalRecipe
                    updatingRecipe = finalRecipe
                    
                    appliedRecommendations.insert(recommendation)
                    
                    updateNutritionData(for: finalRecipe)
                    
                    showCheckmark = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isUpdating = false
                        showCheckmark = false
                        updatingRecipe = nil
                    }
                }
            } catch {
                print("Failed to update recipe: \(error)")
                await MainActor.run {
                    isUpdating = false
                    showCheckmark = false
                    updatingRecipe = nil
                }
            }
        }
    }
    
    private func applyRecommendation(_ recommendation: String, to recipe: Recipe) -> Recipe {
        var updatedRecipe = recipe
        let lowercasedRecommendation = recommendation.lowercased()
        
        if lowercasedRecommendation.contains("add") && lowercasedRecommendation.contains("protein") {
            let proteinIngredients = [
                "1/2 cup cooked quinoa",
                "1/4 cup chopped almonds", 
                "2 tbsp hemp seeds",
                "1/4 cup Greek yogurt"
            ]
            
            for ingredient in proteinIngredients {
                if !updatedRecipe.ingredients.contains(ingredient) {
                    updatedRecipe.ingredients.append(ingredient)
                }
            }
            
            let currentProtein = parseMacroValue(updatedRecipe.macros.protein)
            let newProtein = currentProtein + 15.0
            updatedRecipe.macros = RecipeMacros(
                protein: "\(Int(newProtein))g",
                carbohydrates: updatedRecipe.macros.carbohydrates,
                fat: updatedRecipe.macros.fat
            )
            
            let currentCalories = Int(updatedRecipe.calorieCount) ?? 0
            updatedRecipe.calorieCount = "\(currentCalories + 60)"
            
        } else if lowercasedRecommendation.contains("add") && lowercasedRecommendation.contains("fiber") {
            let fiberIngredients = [
                "1/2 cup mixed vegetables",
                "2 tbsp chia seeds",
                "1/4 cup black beans",
                "1 tbsp ground flaxseed"
            ]
            
            for ingredient in fiberIngredients {
                if !updatedRecipe.ingredients.contains(ingredient) {
                    updatedRecipe.ingredients.append(ingredient)
                }
            }
            
        } else if lowercasedRecommendation.contains("reduce") && lowercasedRecommendation.contains("sodium") {
            updatedRecipe.ingredients = updatedRecipe.ingredients.map { ingredient in
                let lowercased = ingredient.lowercased()
                if lowercased.contains("salt") {
                    return "1/4 tsp sea salt (reduced)"
                } else if lowercased.contains("soy sauce") {
                    return "1 tbsp low-sodium soy sauce"
                } else if lowercased.contains("broth") {
                    return "1 cup low-sodium vegetable broth"
                }
                return ingredient
            }
            
        } else if lowercasedRecommendation.contains("replace") && lowercasedRecommendation.contains("saturated fat") {
            updatedRecipe.ingredients = updatedRecipe.ingredients.map { ingredient in
                let lowercased = ingredient.lowercased()
                if lowercased.contains("butter") {
                    return "2 tbsp olive oil"
                } else if lowercased.contains("cream") {
                    return "1/2 cup coconut milk"
                } else if lowercased.contains("cheese") {
                    return "1/4 cup nutritional yeast"
                }
                return ingredient
            }
            
        } else if lowercasedRecommendation.contains("add") && lowercasedRecommendation.contains("vegetable") {
            let vegetableIngredients = [
                "1 cup mixed leafy greens",
                "1/2 cup diced bell peppers",
                "1/4 cup shredded carrots",
                "1/2 cup cherry tomatoes"
            ]
            
            for ingredient in vegetableIngredients {
                if !updatedRecipe.ingredients.contains(ingredient) {
                    updatedRecipe.ingredients.append(ingredient)
                }
            }
        }
        
        updatedRecipe.description = "\(updatedRecipe.description) (Nutritionally enhanced)"
        
        return updatedRecipe
    }
    
    private func parseMacroValue(_ value: String) -> Double {
        let cleaned = value.replacingOccurrences(of: "g", with: "")
            .replacingOccurrences(of: " ", with: "")
        return Double(cleaned) ?? 0
    }
}


private struct RecipeCard: View {
    let recipe: Recipe
    let isSelected: Bool
    let isInDiet: Bool
    let onTap: () -> Void
    let onAddToDiet: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .clipped()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                    
                    Text("\(recipe.cuisine) • \(recipe.mealType.capitalized)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(recipe.calorieCount)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("cal")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isInDiet {
                    VStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("Diet")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct NutritionRecipeHeaderView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(recipe.title).font(.title2).bold()
                    Text(recipe.description).font(.caption).foregroundColor(.secondary).lineLimit(2)
                    HStack(spacing: 8) {
                        Text("\(recipe.cuisine)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        Text(recipe.mealType.capitalized)
                             .font(.caption)
                             .padding(.horizontal, 8)
                             .padding(.vertical, 4)
                             .background(Color.green.opacity(0.1))
                             .foregroundColor(.green)
                             .cornerRadius(6)
                    }
                    HStack(spacing: 12) {
                        if let servingSize = recipe.servingSize {
                            Text("Serving size: \(servingSize)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Text("Servings: \(recipe.servings)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        }
        .padding(.bottom, 8)
    }
}

private struct QuickStatsView: View {
    let recipe: Recipe
    let nutrition: NutritionData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Serving Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 12) {
                if let servingSize = recipe.servingSize {
                    Text("Serving size: \(servingSize)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text("Servings: \(recipe.servings)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
            
            Divider()
            
            HStack {
                Text("Quick Stats")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("per serving")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(title: "Calories", value: "\(Int(nutrition.calories))", unit: "cals", color: .orange, showPerServing: true)
                StatCard(title: "Protein", value: "\(Int(nutrition.protein))", unit: "g", color: .green, showPerServing: true)
                StatCard(title: "Carbs", value: "\(Int(nutrition.carbohydrates))", unit: "g", color: .blue, showPerServing: true)
                StatCard(title: "Fat", value: "\(Int(nutrition.fat))", unit: "g", color: .purple, showPerServing: true)
            }
        }
    }
}

private struct StatCard: View {
    let title: String 
    let value: String
    let unit: String
    let color: Color
    let showPerServing: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if showPerServing {
                    Text("per serving")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

private struct MacroBreakdownView: View {
    let nutrition: NutritionData
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 16) {
            Text("Macro Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .center) 
            
            VStack(spacing: 20) {
                DonutChartView(nutrition: nutrition)
                    .frame(height: 200)
                    .frame(maxWidth: 300, alignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.leading, 55)
                
                VStack(alignment: .leading, spacing: 12) {
                    MacroDetailRow(
                        name: "Protein",
                        value: nutrition.protein,
                        unit: "g",
                        color: .green
                    )
                    
                    MacroDetailRow(
                        name: "Carbs",
                        value: nutrition.carbohydrates,
                        unit: "g",
                        color: .blue
                    )
                    
                    MacroDetailRow(
                        name: "Fat",
                        value: nutrition.fat,
                        unit: "g",
                        color: .purple
                    )
                }
                .frame(maxWidth: 300) 
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity) 
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

private struct DonutChartView: View {
    let nutrition: NutritionData
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 20
            
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 20)
                
                Circle()
                    .trim(from: 0, to: proteinPercentage)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: proteinPercentage, to: proteinPercentage + carbsPercentage)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: proteinPercentage + carbsPercentage, to: 1.0)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(totalMacros))")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total g/serving")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var proteinPercentage: Double {
        totalMacros > 0 ? nutrition.protein / totalMacros : 0
    }
    
    private var carbsPercentage: Double {
        totalMacros > 0 ? nutrition.carbohydrates / totalMacros : 0
    }
    
    private var totalMacros: Double {
        nutrition.protein + nutrition.carbohydrates + nutrition.fat
    }
}

private struct MacroDetailRow: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(formatValue(value))
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    private func formatValue(_ v: Double) -> String {
        if v == 0 { return "0" }
        if v < 1 { return String(format: "%.1f", v) }
        if v < 10 && v != floor(v) { return String(format: "%.1f", v) }
        return String(Int(v))
    }
}

private struct HealthInsightsView: View {
    let insights: [HealthInsight]
    let onApplyRecommendation: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(insights.enumerated()), id: \.offset) { index, insight in
                    HealthInsightCard(insight: insight, onApplyRecommendation: onApplyRecommendation)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

private struct HealthInsightCard: View {
    let insight: HealthInsight
    let onApplyRecommendation: (String) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let recommendation = insight.recommendation {
                    Button(action: {
                        onApplyRecommendation(recommendation)
                    }) {
                        Text(recommendation)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .underline()
                            .padding(.top, 4)
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
    }
    
    private var iconName: String {
        switch insight.type {
        case .positive:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .concern:
            return "xmark.circle.fill"
        case .recommendation:
            return "lightbulb.fill"
        }
    }
    
    private var iconColor: Color {
        switch insight.type {
        case .positive:
            return .green
        case .warning:
            return .orange
        case .concern:
            return .red
        case .recommendation:
            return .blue
        }
    }
    
    private var backgroundColor: Color {
        switch insight.type {
        case .positive:
            return .green.opacity(0.1)
        case .warning:
            return .orange.opacity(0.1)
        case .concern:
            return .red.opacity(0.1)
        case .recommendation:
            return .blue.opacity(0.1)
        }
    }
}

private struct MicronutrientsView: View {
    let nutrition: NutritionData
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Micronutrients")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("per serving")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MicronutrientCard(
                    name: "Fiber",
                    value: nutrition.fiber,
                    unit: "g",
                    dailyValue: 25.0
                )
                
                MicronutrientCard(
                    name: "Sugar",
                    value: nutrition.sugar,
                    unit: "g",
                    dailyValue: 50.0
                )
                
                MicronutrientCard(
                    name: "Sodium",
                    value: nutrition.sodium,
                    unit: "mg",
                    dailyValue: 2300.0
                )
                
                MicronutrientCard(
                    name: "Cholesterol",
                    value: nutrition.cholesterol,
                    unit: "mg",
                    dailyValue: 300.0
                )

                MicronutrientCard(
                    name: "Saturated Fat",
                    value: nutrition.saturatedFat,
                    unit: "g",
                    dailyValue: 20.0
                )

                MicronutrientCard(
                    name: "Trans Fat",
                    value: nutrition.transFat,
                    unit: "g",
                    dailyValue: 2.0
                )
            }
            
            if !nutrition.vitamins.isEmpty || !nutrition.minerals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    if !nutrition.vitamins.isEmpty {
                        Text("Vitamins")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(nutrition.vitamins, id: \.name) { vitamin in
                            VitaminMineralRow(
                                name: vitamin.name,
                                amount: vitamin.amount,
                                unit: vitamin.unit,
                                dailyValue: vitamin.dailyValue
                            )
                        }
                    }
                    
                    if !nutrition.minerals.isEmpty {
                        Text("Minerals")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(nutrition.minerals, id: \.name) { mineral in
                            VitaminMineralRow(
                                name: mineral.name,
                                amount: mineral.amount,
                                unit: mineral.unit,
                                dailyValue: mineral.dailyValue
                            )
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

private struct MicronutrientCard: View {
    let name: String
    let value: Double
    let unit: String
    let dailyValue: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formatValue(value))
                    .font(.headline)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: geo.size.width * min(1.0, value / dailyValue))
                }
            }
            .frame(height: 4)
            
            Text("\(Int((value / dailyValue) * 100))% of daily value")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    private var progressColor: Color {
        let percentage = value / dailyValue
        if percentage > 1.0 {
            return .red
        } else if percentage > 0.8 {
            return .orange
        } else {
            return .green
        }
    }

    private func formatValue(_ v: Double) -> String {
        if v == 0 { return "0" }
        if v < 1 { return String(format: "%.1f", v) }
        if v < 10 && v != floor(v) { return String(format: "%.1f", v) }
        return String(Int(v))
    }
}

private struct VitaminMineralRow: View {
    let name: String
    let amount: Double
    let unit: String
    let dailyValue: Double
    
    var body: some View {
        HStack {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
            
                Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formatValue(amount))
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if dailyValue > 0 {
                Text("(\(Int((amount / dailyValue) * 100))%)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatValue(_ v: Double) -> String {
        if v == 0 { return "0" }
        if v < 1 { return String(format: "%.1f", v) }
        if v < 10 && v != floor(v) { return String(format: "%.1f", v) }
        return String(Int(v))
    }
}


private struct NutritionTrendsView: View {
    let trends: [NutritionTrend]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Average Nutrition")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("(across all recipes)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ForEach(trends, id: \.period) { trend in
                VStack(alignment: .leading, spacing: 12) {
                    Text(trend.period)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        TrendCard(title: "Calories", value: trend.averageCalories, unit: "cals", color: .orange, isCalories: true)
                        TrendCard(title: "Protein", value: trend.averageProtein, unit: "g", color: .green, isCalories: false)
                        TrendCard(title: "Carbs", value: trend.averageCarbs, unit: "g", color: .blue, isCalories: false)
                        TrendCard(title: "Fat", value: trend.averageFat, unit: "g", color: .purple, isCalories: false)
                    }
                    
                    Text("per serving")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, 4)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

private struct TrendCard: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    let isCalories: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                let isSmall = title.lowercased() == "calories" || title.lowercased() == "protein"
                Text("\(Int(value))")
                    .font(isSmall ? .caption : .headline)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("avg across recipes")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

private struct IngredientAnalysisView: View {
    let recipe: Recipe
    let nutrition: NutritionData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredient Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    IngredientRow(ingredient: ingredient, types: recipe.ingredientTypes)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

private struct IngredientRow: View {
    let ingredient: String
    let types: [String: [String]]?
    @State private var gptTags: [String] = []
    
    var body: some View {
        HStack(spacing: 12) {
            Text(ingredient)
                .font(.subheadline)
                .lineLimit(2)
            
            Spacer()
            
            let tags = Array(Set(gptTags.map { $0.lowercased() })).sorted()
            let scale: CGFloat = tags.count == 0 ? 1.0 : max(0.65, 1.0 - CGFloat(tags.count - 1) * 0.1)
            let spacing: CGFloat = tags.count == 0 ? 6 : max(2, 8 - CGFloat(tags.count))
            HStack(spacing: spacing) {
                ForEach(tags, id: \.self) { tag in
                    let style = tagStyle(for: tag)
                    TagChip(icon: style.icon, label: style.label, color: style.color, showBackground: style.showBackground)
                        .scaleEffect(scale)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .onAppear { deriveTags() }
    }

    private func deriveTags() {
        guard let types = types else { gptTags = []; return }
        let lower = ingredient.lowercased()
        if let entry = types.first(where: { key, _ in lower.contains(key.lowercased()) }) {
            gptTags = entry.value
        } else {
            gptTags = []
        }
    }

    private func tagStyle(for rawTag: String) -> (icon: String, label: String, color: Color, showBackground: Bool) {
        let tag = rawTag.lowercased()
        switch tag {
        case "spice":
            return ("flame.fill", "Spice", .orange, false)
        case "herb":
            return ("leaf.fill", "Herb", .green, true)
        case "seasoning":
            return ("wand.and.stars", "Seasoning", .yellow, true)
        case "protein":
            return ("p.circle.fill", "Protein", .green, true)
        case "meat":
            return ("fork.knife", "Meat", .red, true)
        case "dairy":
            return ("takeoutbag.and.cup.and.straw.fill", "Dairy", .blue, true)
        case "marinade":
            return ("drop.fill", "Marinade", .teal, true)
        case "fat", "oil":
            return ("circle.hexagongrid.fill", "Fat", .purple, true)
        case "vegetable", "aromatic":
            return ("leaf", "Vegetable", .green, true)
        case "acid":
            return ("drop.triangle.fill", "Acid", .pink, true)
        case "fresh":
            return ("sparkles", "Fresh", .mint, true)
        case "grain", "bread":
            return ("bag.fill", "Grain", .brown, true)
        case "seed paste", "sauce":
            return ("square.and.line.vertical.and.square.fill", "Sauce", .orange, true)
        case "liquid":
            return ("drop.fill", "Liquid", .blue, true)
        case "optional":
            return ("questionmark.circle.fill", "Optional", .gray, true)
        case "cholesterol":
            return ("heart.fill", "Cholesterol", .purple, true)
        case "sodium", "salt":
            return ("bolt.trianglebadge.exclamationmark", "Sodium", .red, true)
        case "vitamin", "vitamin c", "vitamin a", "vitamin d":
            return ("star.fill", "Vitamin", .orange, true)
        default:
            return ("tag.fill", rawTag.capitalized, .gray, true)
        }
    }
}

private struct TagChip: View {
    let icon: String
    let label: String
    let color: Color
    let showBackground: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, showBackground ? 8 : 0)
        .padding(.vertical, showBackground ? 4 : 0)
        .background(
            Group {
                if showBackground {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.12))
                } else {
                    Color.clear
                }
            }
        )
    }
}


private struct NutritionalIndicator: View {
    let icon: String
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}


private struct RecipeListView: View {
    let recipes: [Recipe]
    let dietSet: Set<String>
    let trends: [NutritionTrend]
    let onRecipeTap: (Recipe) -> Void
    let onAddToDiet: (Recipe) -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Nutrition Analytics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Refresh") { 
                        onRefresh()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                
                Text("Saved Recipes")
                    .font(.headline)
            }
            .padding(.horizontal, 20)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recipes) { recipe in
                        RecipeCard(
                            recipe: recipe,
                            isSelected: false,
                            isInDiet: dietSet.contains(recipe.id.uuidString),
                            onTap: { onRecipeTap(recipe) },
                            onAddToDiet: { onAddToDiet(recipe) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

private struct DetailedNutritionView: View {
    let recipe: Recipe
    let nutritionData: NutritionData?
    let healthInsights: [HealthInsight]
    let nutritionTrends: [NutritionTrend]
    let isUpdating: Bool
    let showCheckmark: Bool
    let onBack: () -> Void
    let onApplyRecommendation: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                        Text("Back to Recipes")
                            .font(.headline)
                    }
                    .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Divider()
            
            if let nutrition = nutritionData {
                ScrollView {
                    VStack(spacing: 24) {
                        NutritionRecipeHeaderView(recipe: recipe)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Calories")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(Int(nutrition.calories))")
                                    .font(.system(size: 36))
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                
                                Text("per serving")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let servingSize = recipe.servingSize {
                                Text("Serving size: \(servingSize)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.orange.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
                        
                        
                        
                        MacroBreakdownView(nutrition: nutrition)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Health Insights & Recommendations")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(healthInsights, id: \.title) { insight in
                                    HealthInsightCard(insight: insight, onApplyRecommendation: onApplyRecommendation)
                                }
                            }
                            
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2))
                        
                        MicronutrientsView(nutrition: nutrition)
                        
                        IngredientAnalysisView(recipe: recipe, nutrition: nutrition)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Analyzing nutrition data...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .overlay {
            if isUpdating {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 16) {
                            if showCheckmark {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)
                                Text("Recipe Updated")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            } else {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                Text("Updating Recipe...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
            }
        }
    }
}

