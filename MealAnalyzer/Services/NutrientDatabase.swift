//
//  NutrientDatabase.swift
//  MealAnalyzer
//

import Foundation

final class NutrientDatabase {

    static let shared = NutrientDatabase()

    private var foods: [FoodItem] = []
    private var lookupTable: [String: FoodItem] = [:]

    private init() {
        loadDatabase()
    }

    // MARK: - Loading

    private func loadDatabase() {
        guard let url = Bundle.main.url(forResource: "nutrients", withExtension: "json") else {
            print("NutrientDatabase: nutrients.json not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            foods = try JSONDecoder().decode([FoodItem].self, from: data)
            // Build lookup table with lowercase keys
            for food in foods {
                lookupTable[food.name.lowercased()] = food
            }
        } catch {
            print("NutrientDatabase: Failed to load nutrients.json: \(error)")
        }
    }

    // MARK: - Lookup

    /// Looks up nutrient info for a classifier label.
    /// Food-101 labels use underscores (e.g. "chicken_curry"), which match our JSON keys directly.
    func lookup(_ identifier: String) -> FoodItem? {
        let query = identifier.lowercased().trimmingCharacters(in: .whitespaces)

        // 1. Exact match (covers Food-101 labels directly)
        if let food = lookupTable[query] {
            return food
        }

        // 2. Try replacing spaces with underscores and vice-versa
        let withUnderscores = query.replacingOccurrences(of: " ", with: "_")
        if let food = lookupTable[withUnderscores] {
            return food
        }
        let withSpaces = query.replacingOccurrences(of: "_", with: " ")
        if let food = lookupTable[withSpaces] {
            return food
        }

        // 3. Check if any database key contains the query or vice-versa
        for (key, food) in lookupTable {
            if key.contains(query) || query.contains(key) {
                return food
            }
        }

        // 4. Split into words and try matching individual words
        let words = query
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map(String.init)

        for word in words where word.count > 3 {
            for (key, food) in lookupTable {
                if key.contains(word) {
                    return food
                }
            }
        }

        return nil
    }

    /// Returns the best matching food item for the top classification results.
    func bestMatch(for results: [ClassificationResult]) -> (food: FoodItem, confidence: Float)? {
        for result in results {
            if let food = lookup(result.identifier) {
                return (food, result.confidence)
            }
        }
        return nil
    }

    /// Returns all food items in the database.
    var allFoods: [FoodItem] {
        foods
    }
}
