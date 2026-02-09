//
//  NutrientInfo.swift
//  MealAnalyzer
//

import Foundation

struct NutrientInfo: Codable, Equatable {
    let calories: Double
    let protein: Double      // grams
    let carbs: Double        // grams
    let fat: Double          // grams
    let fiber: Double        // grams
    let sugar: Double        // grams

    static let zero = NutrientInfo(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)
}

struct FoodItem: Codable {
    let name: String
    let servingSize: String
    let nutrients: NutrientInfo
}

struct ClassificationResult {
    let identifier: String
    let confidence: Float
}
