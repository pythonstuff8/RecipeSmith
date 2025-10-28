import Foundation
import SwiftUI

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
           - Fiber (in grams)
           - Sugar (in grams)
           - Sodium (in mg)
           - Cholesterol (in mg)
           - Saturated Fat (in grams)
           - Trans Fat (in grams)
        2. Always include specific dietary labels based on ingredients and nutrition
        
        3. Provide detailed cooking instructions and timing
        4. Include vitamins and minerals arrays with realistic estimates.
        5. Provide ingredient list with amounts and clear instructions.
        6. Also RETURN AN ADDITIONAL FIELD named "serving_size" describing the typical weight/volume per serving (e.g. "100g per serving").
        7. Also RETURN an "ingredient_types" object that maps each ingredient (string) to a list of nutritional tags/categories (e.g. "protein", "fiber", "vitamin_c", "cholesterol", "sodium"). Use concise labels.

        Return ONLY valid JSON (no surrounding markdown) with keys matching the required output, e.g. "ingredient_types": { "shrimp": ["protein","cholesterol"], ... }
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
            "fat": "exact grams per serving",
            "fiber": "exact grams per serving (ALWAYS provide this)",
            "sugar": "exact grams per serving (ALWAYS provide this)",
            "sodium": "exact mg per serving (ALWAYS provide this)",
            "cholesterol": "exact mg per serving (ALWAYS provide this)",
            "saturated_fat": "exact grams per serving (ALWAYS provide this)",
            "trans_fat": "exact grams per serving (ALWAYS provide this)",
            "vitamins": [{"name": "Vitamin Name", "amount": "number", "unit": "unit"}],
            "minerals": [{"name": "Mineral Name", "amount": "number", "unit": "unit"}]
          },
          "ingredients": ["detailed ingredients with amounts"],
          "instructions": ["numbered, detailed steps"],
          "meal": "specific meal type",
          "equipment": ["specific equipment list"],
          "diet": ["all applicable dietary labels"]
        }
        
        IMPORTANT: The vitamins array should include common vitamins found in the ingredients such as Vitamin A, C, D, E, K, and B vitamins. The minerals array should include Iron, Calcium, Potassium, Magnesium, Zinc, etc. Always provide realistic values based on the ingredients used.
        """
        
        return prompt
    }
}
