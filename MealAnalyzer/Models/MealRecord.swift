//
//  MealRecord.swift
//  MealAnalyzer
//

import Foundation
import SwiftData

@Model
final class MealRecord {
    var imageData: Data
    var foodName: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var servingSize: String
    var confidence: Double
    var timestamp: Date

    init(
        imageData: Data,
        foodName: String,
        nutrients: NutrientInfo,
        servingSize: String,
        confidence: Double,
        timestamp: Date = .now
    ) {
        self.imageData = imageData
        self.foodName = foodName
        self.calories = nutrients.calories
        self.protein = nutrients.protein
        self.carbs = nutrients.carbs
        self.fat = nutrients.fat
        self.fiber = nutrients.fiber
        self.sugar = nutrients.sugar
        self.servingSize = servingSize
        self.confidence = confidence
        self.timestamp = timestamp
    }

    var nutrientInfo: NutrientInfo {
        NutrientInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar
        )
    }
}
