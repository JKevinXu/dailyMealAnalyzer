//
//  NutrientCardView.swift
//  MealAnalyzer
//

import SwiftUI

struct NutrientCardView: View {
    let foodName: String
    let servingSize: String
    let nutrients: NutrientInfo
    let confidence: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(foodName.capitalized)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(servingSize)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ConfidenceBadge(confidence: confidence)
            }

            Divider()

            // Calories (prominent)
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                Text("Calories")
                    .font(.headline)
                Spacer()
                Text("\(Int(nutrients.calories))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
                Text("kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Macronutrients
            VStack(spacing: 12) {
                NutrientRow(name: "Protein", value: nutrients.protein, unit: "g",
                            color: .red, maxValue: 60)
                NutrientRow(name: "Carbs", value: nutrients.carbs, unit: "g",
                            color: .blue, maxValue: 80)
                NutrientRow(name: "Fat", value: nutrients.fat, unit: "g",
                            color: .yellow, maxValue: 40)
                NutrientRow(name: "Fiber", value: nutrients.fiber, unit: "g",
                            color: .green, maxValue: 15)
                NutrientRow(name: "Sugar", value: nutrients.sugar, unit: "g",
                            color: .purple, maxValue: 50)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sub-components

private struct NutrientRow: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color
    let maxValue: Double

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f", value))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                + Text(" \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                        .frame(height: 6)
                    Capsule()
                        .fill(color)
                        .frame(width: min(geo.size.width * (value / maxValue), geo.size.width), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

private struct ConfidenceBadge: View {
    let confidence: Double

    var label: String {
        switch confidence {
        case 0.7...: return "High"
        case 0.4...: return "Medium"
        default: return "Low"
        }
    }

    var color: Color {
        switch confidence {
        case 0.7...: return .green
        case 0.4...: return .orange
        default: return .red
        }
    }

    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview {
    NutrientCardView(
        foodName: "Pizza",
        servingSize: "1 slice (107g)",
        nutrients: NutrientInfo(calories: 285, protein: 12, carbs: 36, fat: 10, fiber: 2.5, sugar: 4),
        confidence: 0.85
    )
    .padding()
}
