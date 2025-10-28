import Foundation

class IngredientService {
    static let shared = IngredientService()
    private let usdaApiKey = Configuration.usdaApiKey
    private let spoonacularApiKey = Configuration.spoonacularApiKey
    private let usdaBaseURL = "https://api.nal.usda.gov/fdc/v1"
    private let spoonacularBaseURL = "https://api.spoonacular.com/food/ingredients"
    
    private init() {}
    
    func searchIngredients(query: String) async throws -> [IngredientDetail] {
        guard !query.isEmpty else { return [] }
        
        let ingredients = try await searchUSDA(query: query)
        
        var detailedIngredients: [IngredientDetail] = []
        
        for var ingredient in ingredients {
            if let imageUrl = try? await fetchIngredientImage(name: ingredient.name) {
                ingredient.imageUrl = imageUrl
            }
            detailedIngredients.append(ingredient)
        }
        
        return detailedIngredients
    }
    
    private func searchUSDA(query: String) async throws -> [IngredientDetail] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(usdaBaseURL)/foods/search?api_key=\(usdaApiKey)&query=\(encodedQuery)&pageSize=25"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let searchResponse = try JSONDecoder().decode(FoodSearchResponse.self, from: data)
        return searchResponse.foods.map { food in
            IngredientDetail(
                id: food.fdcId,
                name: food.description,
                calories: food.foodNutrients.first { $0.nutrientName == "Energy" }?.value ?? 0,
                protein: food.foodNutrients.first { $0.nutrientName == "Protein" }?.value ?? 0,
                carbs: food.foodNutrients.first { $0.nutrientName == "Carbohydrate, by difference" }?.value ?? 0,
                fat: food.foodNutrients.first { $0.nutrientName == "Total lipid (fat)" }?.value ?? 0,
                servingSize: food.servingSize ?? 100,
                servingSizeUnit: food.servingSizeUnit ?? "g",
                imageUrl: nil
            )
        }
    }
    
    private func fetchIngredientImage(name: String) async throws -> String? {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let urlString = "\(spoonacularBaseURL)/search?query=\(encodedName)&apiKey=\(spoonacularApiKey)&number=1"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let searchResponse = try JSONDecoder().decode(SpoonacularSearchResponse.self, from: data)
        guard let firstResult = searchResponse.results.first else {
            return nil
        }
        
        return "https://spoonacular.com/cdn/ingredients_100x100/\(firstResult.image)"
    }
}

struct FoodSearchResponse: Codable {
    let foods: [Food]
    
    struct Food: Codable {
        let fdcId: Int
        let description: String
        let foodNutrients: [FoodNutrient]
        let servingSize: Double?
        let servingSizeUnit: String?
    }
    
    struct FoodNutrient: Codable {
        let nutrientName: String
        let value: Double
    }
}

struct SpoonacularSearchResponse: Codable {
    let results: [SpoonacularIngredient]
    
    struct SpoonacularIngredient: Codable {
        let id: Int
        let name: String
        let image: String
    }
}
