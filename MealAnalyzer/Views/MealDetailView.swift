//
//  MealDetailView.swift
//  MealAnalyzer
//

import SwiftUI

struct MealDetailView: View {
    let meal: MealRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Meal image
                if let uiImage = UIImage(data: meal.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }

                // Timestamp
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text(meal.timestamp, format: .dateTime.month().day().year().hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)

                // Nutrient card
                NutrientCardView(
                    foodName: meal.foodName,
                    servingSize: meal.servingSize,
                    nutrients: meal.nutrientInfo,
                    confidence: meal.confidence
                )
                .padding(.horizontal)

                // Delete button
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Meal", systemImage: "trash")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(meal.foodName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Meal?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(meal)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this meal from your history.")
        }
    }
}

#Preview {
    NavigationStack {
        MealDetailView(meal: MealRecord(
            imageData: Data(),
            foodName: "Pizza",
            nutrients: NutrientInfo(calories: 285, protein: 12, carbs: 36, fat: 10, fiber: 2.5, sugar: 4),
            servingSize: "1 slice (107g)",
            confidence: 0.85
        ))
    }
}
