//
//  HistoryView.swift
//  MealAnalyzer
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealRecord.timestamp, order: .reverse) private var meals: [MealRecord]

    var body: some View {
        NavigationStack {
            Group {
                if meals.isEmpty {
                    emptyState
                } else {
                    mealList
                }
            }
            .navigationTitle("History")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56))
                .foregroundStyle(.green.opacity(0.5))
            Text("No Meals Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Analyzed meals you save will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Meal List

    private var mealList: some View {
        List {
            // Today's summary
            if !todayMeals.isEmpty {
                Section {
                    DailySummaryCard(meals: todayMeals)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            // All meals
            Section("All Meals") {
                ForEach(meals) { meal in
                    NavigationLink(destination: MealDetailView(meal: meal)) {
                        MealRowView(meal: meal)
                    }
                }
                .onDelete(perform: deleteMeals)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var todayMeals: [MealRecord] {
        meals.filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    private func deleteMeals(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(meals[index])
        }
    }
}

// MARK: - Meal Row

private struct MealRowView: View {
    let meal: MealRecord

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let uiImage = UIImage(data: meal.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.green.opacity(0.1))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.green)
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.foodName.capitalized)
                    .font(.headline)
                Text("\(Int(meal.calories)) kcal")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }

            Spacer()

            // Time
            Text(meal.timestamp, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Daily Summary

private struct DailySummaryCard: View {
    let meals: [MealRecord]

    private var totalCalories: Double {
        meals.reduce(0) { $0 + $1.calories }
    }

    private var totalProtein: Double {
        meals.reduce(0) { $0 + $1.protein }
    }

    private var totalCarbs: Double {
        meals.reduce(0) { $0 + $1.carbs }
    }

    private var totalFat: Double {
        meals.reduce(0) { $0 + $1.fat }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.orange)
                Text("Today's Summary")
                    .font(.headline)
                Spacer()
                Text("\(meals.count) meal\(meals.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                SummaryPill(label: "Calories", value: "\(Int(totalCalories))", unit: "kcal", color: .orange)
                SummaryPill(label: "Protein", value: String(format: "%.0f", totalProtein), unit: "g", color: .red)
                SummaryPill(label: "Carbs", value: String(format: "%.0f", totalCarbs), unit: "g", color: .blue)
                SummaryPill(label: "Fat", value: String(format: "%.0f", totalFat), unit: "g", color: .yellow)
            }
        }
        .padding()
        .background(.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}

private struct SummaryPill: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: MealRecord.self, inMemory: true)
}
