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

/// Unified result returned by the LLM analysis.
struct AnalysisResult {
    let foodName: String
    let servingSize: String
    let nutrients: NutrientInfo
    let confidence: Double
}
