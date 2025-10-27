import Foundation

class RecipeService {
    static let shared = RecipeService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    func generateRecipe(ingredients: [String], allowOtherIngredients: Bool, extraDetails: [String: Any]? = nil) async throws -> Recipe {
        let prompt = createPrompt(ingredients: ingredients, allowOtherIngredients: allowOtherIngredients, extraDetails: extraDetails)
        
        do {
            let recipe = try await apiService.generateRecipe(prompt: prompt)
            return recipe
        } catch {
            throw error
        }
    }
    
    private func createPrompt(ingredients: [String], allowOtherIngredients: Bool, extraDetails: [String: Any]?) -> String {
        var prompt = """
        Create a recipe using these ingredients:
        - \(ingredients.joined(separator: "\n- "))
        
        IMPORTANT REQUIREMENTS:
        1. Calculate and include exact nutritional information per serving:
           - Calories (must be a specific number)
           - Protein (in grams)
           - Carbohydrates (in grams)
           - Fat (in grams)
        
        2. Always include specific dietary labels based on ingredients and nutrition
        
        3. Provide detailed cooking instructions and timing
        
        """
        
        if !allowOtherIngredients {
            prompt += """
            CRITICAL: Use ONLY the listed ingredients. Do not add any others.
            Be creative with only these ingredients.
            """
        }
        
        if let details = extraDetails {
            prompt += "Additional requirements:\n"
            
            if let fatMin = details["fat_min"] as? Int { prompt += "Minimum Fat Per Serving Of The Dish Will Be: \(fatMin)\n" }
            if let fatMax = details["fat_max"] as? Int { prompt += "Maximum Fat Per Serving Of The Dish Will Be: \(fatMax)\n" }
            if let proteinMin = details["protein_min"] as? Int { prompt += "Minimum Protein Per Serving Of The Dish Will Be: \(proteinMin)\n" }
            if let proteinMax = details["protein_max"] as? Int { prompt += "Maximum Protein Per Serving Of The Dish Will Be: \(proteinMax)\n" }
            if let carbsMin = details["carbs_min"] as? Int { prompt += "Minimum Carbohydrates Per Serving Of The Dish Will Be: \(carbsMin)\n" }
            if let carbsMax = details["carbs_max"] as? Int { prompt += "Maximum Carbohydrates Per Serving Of The Dish Will Be: \(carbsMax)\n" }
            if let caloriesMin = details["calories_min"] as? Int { prompt += "Minimum Calories Per Serving Of The Dish Will Be: \(caloriesMin)\n" }
            if let caloriesMax = details["calories_max"] as? Int { prompt += "Maximum Calories Per Serving Of The Dish Will Be: \(caloriesMax)\n" }
            
            if let allergies = details["allergies"] as? [String] {
                prompt += "\nAllergies/Restrictions to avoid:\n- " + allergies.joined(separator: "\n- ") + "\n"
            }
            
            if let dietPreferences = details["diet_preferences"] as? [String] {
                prompt += "\nDietary Preferences:\n- " + dietPreferences.joined(separator: "\n- ") + "\n"
            }
            
            if let mealTypes = details["meal_types"] as? [String] {
                prompt += "\nThe Meal Type Will Be:\n- " + mealTypes.joined(separator: "\n- ") + "\n"
            }
            
            if let cuisineTypes = details["cuisine_types"] as? [String] {
                prompt += "\nThe Dish Cuisine Type Will Be:\n- " + cuisineTypes.joined(separator: "\n- ") + "\n"
            }
            
            if let equipment = details["equipment"] as? [String] {
                prompt += "\nAvailable Equipment:\n- " + equipment.joined(separator: "\n- ") + "\n"
            }
            
            if let servingSize = details["serving_size"] as? String {
                prompt += "\nServing Size: \(servingSize)\n"
            }
            
            if let timeConstraint = details["time_constraint"] as? String {
                prompt += "\nTime Constraint: \(timeConstraint)\n"
            }
            
            if let notes = details["notes"] as? String {
                prompt += "\nAdditional Notes:\n\(notes)\n"
            }
            
            if let popularDish = details["popular_dish"] as? String {
                prompt += "\nThis should be a recipe for: \(popularDish)\n"
            }
            
            if let popularNotes = details["popular_notes"] as? String, !popularNotes.isEmpty {
                prompt += "\nAdditional notes for popular dish:\n\(popularNotes)\n"
            }
        }
        
        prompt += """
        \nReturn ONLY a JSON object with these REQUIRED fields:
        {
          "cuisine": "specific cuisine type",
          "title": "descriptive recipe name",
          "description": "detailed description",
          "imgdesc": "very detailed visual description for image generation",
          "servings": "specific number",
          "prep": "exact time",
          "cook": "exact time",
          "total": "exact total time",
          "cal": "EXACT number per serving",
          "macros": {
            "protein": "exact grams per serving",
            "carbohydrates": "exact grams per serving",
            "fat": "exact grams per serving"
          },
          "ingredients": ["detailed ingredients with amounts"],
          "instructions": ["numbered, detailed steps"],
          "meal": "specific meal type",
          "equipment": ["specific equipment list"],
          "diet": ["all applicable dietary labels"]
        }
        """
        
        return prompt
    }
}
