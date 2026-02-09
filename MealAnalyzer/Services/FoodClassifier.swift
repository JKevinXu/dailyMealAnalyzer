//
//  FoodClassifier.swift
//  MealAnalyzer
//

import UIKit
import Vision
import CoreML

final class FoodClassifier {

    static let shared = FoodClassifier()

    private var vnModel: VNCoreMLModel?

    private init() {
        loadModel()
    }

    // MARK: - Model loading

    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            let food101 = try Food101(configuration: config)
            vnModel = try VNCoreMLModel(for: food101.model)
        } catch {
            print("FoodClassifier: Failed to load Food101 model – \(error.localizedDescription)")
        }
    }

    // MARK: - Classification

    /// Classifies the given image and returns top food results sorted by confidence.
    func classify(image: UIImage, maxResults: Int = 5) async throws -> [ClassificationResult] {
        guard let cgImage = image.cgImage else {
            throw ClassifierError.invalidImage
        }

        guard let model = vnModel else {
            throw ClassifierError.modelNotLoaded
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let topResults = observations
                    .prefix(maxResults)
                    .map { ClassificationResult(identifier: $0.identifier, confidence: $0.confidence) }

                continuation.resume(returning: Array(topResults))
            }

            // Let Vision handle resizing/cropping to 224x224
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - Errors

enum ClassifierError: LocalizedError {
    case invalidImage
    case modelNotLoaded
    case noResults

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process the image."
        case .modelNotLoaded:
            return "The food recognition model could not be loaded. Please ensure Food101.mlpackage is included in the project."
        case .noResults:
            return "No food items were detected in the image."
        }
    }
}
