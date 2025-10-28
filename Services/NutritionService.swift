import Foundation
import SwiftUI

struct NutritionData {
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let cholesterol: Double
    let saturatedFat: Double
    let transFat: Double
    let vitamins: [VitaminData]
    let minerals: [MineralData]
}

struct VitaminData {
    let name: String
    let amount: Double
    let unit: String
    let dailyValue: Double
}

struct MineralData {
    let name: String
    let amount: Double
    let unit: String
    let dailyValue: Double
}

struct HealthInsight {
    let type: InsightType
    let title: String
    let description: String
    let severity: Severity
    let recommendation: String?
}

enum InsightType {
    case positive
    case warning
    case concern
    case recommendation
}

enum Severity {
    case low
    case medium
    case high
}

struct NutritionTrend {
    let period: String
    let averageCalories: Double
    let averageProtein: Double
    let averageCarbs: Double
    let averageFat: Double
    let trend: TrendDirection
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
}

class NutritionService {
    static let shared = NutritionService()
    
    private init() {}
    
    func calculateNutritionData(from recipe: Recipe) -> NutritionData {
        let calories = Double(recipe.calorieCount) ?? 0
        let protein = parseMacroValue(recipe.macros.protein)
        let carbs = parseMacroValue(recipe.macros.carbohydrates)
        let fat = parseMacroValue(recipe.macros.fat)
        
        let fiber = parseMacroValue(recipe.macros.fiber ?? "0g")
        let sugar = parseMacroValue(recipe.macros.sugar ?? "0g")
        var sodium = parseMacroValue(recipe.macros.sodium ?? "0mg")
        var cholesterol = parseMacroValue(recipe.macros.cholesterol ?? "0mg")
        let saturatedFat = parseMacroValue(recipe.macros.saturatedFat ?? "0g")
        let transFat = parseMacroValue(recipe.macros.transFat ?? "0g")
        
        if sodium <= 0 || cholesterol <= 0 {
            if let typesMap = recipe.ingredientTypes, !typesMap.isEmpty {
                for (ing, tags) in typesMap {
                    let lower = ing.lowercased()
                    if sodium <= 0 {
                        if tags.contains(where: { $0.contains("sodium") || $0.contains("salt") } )
                            || lower.contains("soy sauce") || lower.contains("salt") || lower.contains("broth") || lower.contains("bouillon") || lower.contains("bacon") || lower.contains("cheese") {
                            sodium += 400.0
                        }
                    }
                    if cholesterol <= 0 {
                        if tags.contains(where: { $0.contains("cholesterol") || $0.contains("high_cholesterol") })
                            || lower.contains("egg") || lower.contains("shrimp") || lower.contains("shellfish") || lower.contains("butter") || lower.contains("cheese") || lower.contains("lamb") || lower.contains("bacon") {
                            cholesterol += 120.0
                        }
                    }
                }
            }
            if sodium <= 0 || cholesterol <= 0 {
                for ing in recipe.ingredients {
                    let lower = ing.lowercased()
                    if sodium <= 0 {
                        if lower.contains("soy sauce") { sodium += 900 }
                        else if lower.contains("broth") || lower.contains("bouillon") { sodium += 700 }
                        else if lower.contains("cheese") { sodium += 250 }
                        else if lower.contains("bacon") || lower.contains("salami") { sodium += 300 }
                        else if lower.contains("salt") { sodium += 500 }
                    }
                    if cholesterol <= 0 {
                        if lower.contains("egg") { cholesterol += 186 } 
                        else if lower.contains("shrimp") { cholesterol += 150 } 
                        else if lower.contains("butter") { cholesterol += 30 }
                        else if lower.contains("cheese") { cholesterol += 30 }
                        else if lower.contains("lamb") || lower.contains("beef") || lower.contains("pork") { cholesterol += 40 }
                    }
                }
            }
            sodium = min(max(0, sodium), 5000)
            cholesterol = min(max(0, cholesterol), 1000)
        }
        
        let vitamins = (recipe.macros.vitamins ?? []).map { v in
            VitaminData(name: v.name, amount: Double(v.amount) ?? 0, unit: v.unit, dailyValue: getDailyValue(for: v.name))
        }
        
        let minerals = (recipe.macros.minerals ?? []).map { m in
            MineralData(name: m.name, amount: Double(m.amount) ?? 0, unit: m.unit, dailyValue: getDailyValue(for: m.name))
        }
        
        return NutritionData(
            calories: calories,
            protein: protein,
            carbohydrates: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            cholesterol: cholesterol,
            saturatedFat: saturatedFat,
            transFat: transFat,
            vitamins: vitamins,
            minerals: minerals
        )
    }
    
    func generateHealthInsights(for nutritionData: NutritionData) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        if nutritionData.protein > 25 {
            insights.append(HealthInsight(
                type: .positive,
                title: "High Protein Content",
                description: "This recipe provides excellent protein content for muscle building and satiety. Great for post-workout meals or when you need sustained energy.",
                severity: .low,
                recommendation: nil
            ))
        } else if nutritionData.protein < 10 {
            insights.append(HealthInsight(
                type: .warning,
                title: "Low Protein Content",
                description: "This recipe is relatively low in protein.",
                severity: .medium,
                recommendation: "Consider adding lean protein sources like chicken, fish, or legumes."
            ))
        }
        
        if nutritionData.fiber > 8 {
            insights.append(HealthInsight(
                type: .positive,
                title: "High Fiber Content",
                description: "Excellent fiber content supports digestive health and helps maintain stable blood sugar.",
                severity: .low,
                recommendation: nil
            ))
        } else if nutritionData.fiber < 3 {
            insights.append(HealthInsight(
                type: .concern,
                title: "Low Fiber Content",
                description: "This recipe could benefit from more fiber-rich ingredients.",
                severity: .medium,
                recommendation: "Add vegetables, whole grains, or legumes to increase fiber content."
            ))
        }
        
        if nutritionData.sodium > 800 {
            insights.append(HealthInsight(
                type: .warning,
                title: "High Sodium Content",
                description: "This recipe contains high sodium levels.",
                severity: .high,
                recommendation: "Consider reducing salt or using low-sodium alternatives."
            ))
        }
        
        let saturatedFatPercentage = (nutritionData.saturatedFat / nutritionData.fat) * 100
        if saturatedFatPercentage > 30 {
            insights.append(HealthInsight(
                type: .warning,
                title: "High Saturated Fat",
                description: "This recipe has a high percentage of saturated fat.",
                severity: .medium,
                recommendation: "Consider using healthier fat sources like olive oil or avocado."
            ))
        }
        
        let calorieDensity = nutritionData.calories / max(1, nutritionData.protein + nutritionData.carbohydrates + nutritionData.fat)
        if calorieDensity > 4 {
            insights.append(HealthInsight(
                type: .concern,
                title: "High Calorie Density",
                description: "This recipe is calorie-dense with relatively low nutritional value.",
                severity: .medium,
                recommendation: "Consider adding more vegetables or reducing high-calorie ingredients."
            ))
        }
        
        return insights
    }
    
    func analyzeNutritionTrends(from recipes: [Recipe]) -> [NutritionTrend] {
        guard !recipes.isEmpty else { return [] }
        
        let recipesData = recipes.map { calculateNutritionData(from: $0) }
        
        let avgCalories = recipesData.reduce(0) { $0 + $1.calories } / Double(recipes.count)
        let avgProtein = recipesData.reduce(0) { $0 + $1.protein } / Double(recipes.count)
        let avgCarbs = recipesData.reduce(0) { $0 + $1.carbohydrates } / Double(recipes.count)
        let avgFat = recipesData.reduce(0) { $0 + $1.fat } / Double(recipes.count)
        
        return [
            NutritionTrend(
                period: "All Time",
                averageCalories: avgCalories,
                averageProtein: avgProtein,
                averageCarbs: avgCarbs,
                averageFat: avgFat,
                trend: .stable
            )
        ]
    }
    
    func getDietaryRecommendations(for nutritionData: NutritionData) -> [String] {
        var recommendations: [String] = []
        
        if nutritionData.protein < 20 {
            recommendations.append("Consider adding lean protein sources like chicken breast, fish, or tofu")
        }
        
        if nutritionData.fiber < 5 {
            recommendations.append("Add more vegetables, fruits, or whole grains to increase fiber content")
        }
        
        if nutritionData.saturatedFat > nutritionData.fat * 0.3 {
            recommendations.append("Replace saturated fats with unsaturated fats like olive oil or nuts")
        }
        
        if nutritionData.sodium > 600 {
            recommendations.append("Reduce sodium by using herbs, spices, or low-sodium alternatives")
        }
        
        return recommendations
    }
    
    private func parseMacroValue(_ value: String) -> Double {
        let cleaned = value.replacingOccurrences(of: "g", with: "")
            .replacingOccurrences(of: "mg", with: "")
            .replacingOccurrences(of: " ", with: "")
        return Double(cleaned) ?? 0
    }
    
    private func getDailyValue(for nutrientName: String) -> Double {
        let name = nutrientName.lowercased()
        if name.contains("vitamin c") || name.contains("vit c") {
            return 90.0
        } else if name.contains("vitamin a") || name.contains("vit a") {
            return 900.0
        } else if name.contains("iron") {
            return 18.0
        } else if name.contains("calcium") {
            return 1000.0
        } else if name.contains("vitamin d") || name.contains("vit d") {
            return 20.0
        } else if name.contains("vitamin e") || name.contains("vit e") {
            return 15.0
        } else if name.contains("vitamin k") || name.contains("vit k") {
            return 120.0
        } else if name.contains("thiamin") || name.contains("vitamin b1") {
            return 1.2
        } else if name.contains("riboflavin") || name.contains("vitamin b2") {
            return 1.3
        } else if name.contains("niacin") || name.contains("vitamin b3") {
            return 16.0
        } else if name.contains("vitamin b6") {
            return 1.7
        } else if name.contains("folate") || name.contains("folic acid") {
            return 400.0
        } else if name.contains("vitamin b12") {
            return 2.4
        }
        return 0
    }
}
