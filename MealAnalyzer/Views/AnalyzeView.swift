//
//  AnalyzeView.swift
//  MealAnalyzer
//

import SwiftUI
import SwiftData

struct AnalyzeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var isAnalyzing = false
    @State private var analysisResult: AnalysisResult?
    @State private var errorMessage: String?
    @State private var showSavedConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Image area
                    imageSection

                    // Action buttons
                    if analysisResult == nil {
                        captureButtons
                    }

                    // Analysis progress
                    if isAnalyzing {
                        ProgressView("Analyzing your meal...")
                            .padding()
                    }

                    // Error message
                    if let errorMessage {
                        errorBanner(errorMessage)
                    }

                    // Results
                    if let result = analysisResult {
                        NutrientCardView(
                            foodName: result.foodName,
                            servingSize: result.servingSize,
                            nutrients: result.nutrients,
                            confidence: result.confidence
                        )
                        .padding(.horizontal)

                        actionButtons(for: result)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Analyze Meal")
            .sheet(isPresented: $showCamera) {
                CameraPicker(sourceType: .camera, selectedImage: $selectedImage)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showPhotoLibrary) {
                CameraPicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedImage) { _, newImage in
                if newImage != nil {
                    analyzeImage()
                }
            }
            .overlay {
                if showSavedConfirmation {
                    savedOverlay
                }
            }
        }
    }

    // MARK: - Image Section

    @ViewBuilder
    private var imageSection: some View {
        if let selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green.opacity(0.6))
            Text("Take a photo of your meal")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("We'll identify the food and show\nits nutritional information")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(.green.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Capture Buttons

    private var captureButtons: some View {
        HStack(spacing: 16) {
            Button {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showCamera = true
                } else {
                    errorMessage = "Camera is not available on this device."
                }
            } label: {
                Label("Camera", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Button {
                showPhotoLibrary = true
            } label: {
                Label("Library", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
        .padding(.horizontal)
    }

    // MARK: - Action Buttons (after analysis)

    private func actionButtons(for result: AnalysisResult) -> some View {
        HStack(spacing: 16) {
            Button {
                saveMeal(result)
            } label: {
                Label("Save Meal", systemImage: "square.and.arrow.down.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Button {
                reset()
            } label: {
                Label("New Photo", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
        .padding(.horizontal)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
            Spacer()
            Button {
                errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Saved Overlay

    private var savedOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Meal Saved!")
                .font(.headline)
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Analysis

    private func analyzeImage() {
        guard let image = selectedImage else { return }
        isAnalyzing = true
        errorMessage = nil
        analysisResult = nil

        Task {
            do {
                let results = try await FoodClassifier.shared.classify(image: image)

                if results.isEmpty {
                    errorMessage = "No food items detected. Try a clearer photo."
                    isAnalyzing = false
                    return
                }

                if let match = NutrientDatabase.shared.bestMatch(for: results) {
                    analysisResult = AnalysisResult(
                        foodName: match.food.name,
                        servingSize: match.food.servingSize,
                        nutrients: match.food.nutrients,
                        confidence: Double(match.confidence)
                    )
                } else {
                    // Show best classification even without nutrient data
                    let best = results[0]
                    errorMessage = "Detected \"\(best.identifier)\" but no nutrient data available. Try a different food."
                }
            } catch {
                errorMessage = error.localizedDescription
            }

            isAnalyzing = false
        }
    }

    // MARK: - Save

    private func saveMeal(_ result: AnalysisResult) {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.7) else { return }

        let record = MealRecord(
            imageData: imageData,
            foodName: result.foodName,
            nutrients: result.nutrients,
            servingSize: result.servingSize,
            confidence: result.confidence
        )

        modelContext.insert(record)

        withAnimation(.spring(duration: 0.4)) {
            showSavedConfirmation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSavedConfirmation = false
            }
            reset()
        }
    }

    // MARK: - Reset

    private func reset() {
        selectedImage = nil
        analysisResult = nil
        errorMessage = nil
    }
}

// MARK: - Analysis Result

private struct AnalysisResult {
    let foodName: String
    let servingSize: String
    let nutrients: NutrientInfo
    let confidence: Double
}

#Preview {
    AnalyzeView()
        .modelContainer(for: MealRecord.self, inMemory: true)
}
