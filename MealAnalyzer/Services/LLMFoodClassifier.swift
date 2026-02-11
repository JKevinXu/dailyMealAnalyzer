//
//  LLMFoodClassifier.swift
//  MealAnalyzer
//

import UIKit
import Foundation

final class LLMFoodClassifier {

    static let shared = LLMFoodClassifier()
    private init() {}

    // MARK: - Public API

    /// Sends the image to OpenAI Vision API and returns a full AnalysisResult
    /// with food identification AND nutrient estimation done entirely by the LLM.
    func analyze(image: UIImage) async throws -> AnalysisResult {
        let apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        guard !apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }

        guard let jpegData = image.jpegData(compressionQuality: 0.6) else {
            throw LLMError.imageEncodingFailed
        }

        let base64Image = jpegData.base64EncodedString()

        // Build request
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "system",
                    "content": """
                        You are a nutrition expert. Given a photo of a meal, identify the food \
                        and estimate its nutritional content per typical serving. \
                        Respond ONLY with a JSON object (no markdown, no code fences) using this exact schema: \
                        {"food_name":"...","serving_size":"...","calories":0,"protein":0,"carbs":0,"fat":0,"fiber":0,"sugar":0} \
                        All numeric values should be numbers (not strings). \
                        Calories in kcal, all others in grams. \
                        If the image doesn't contain food, set food_name to "unknown" and all values to 0.
                        """
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "What food is in this photo? Please identify it and estimate the nutritional content per serving."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "low"   // "low" keeps token cost down
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300,
            "temperature": 0.2
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Send
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // Parse OpenAI response
        return try parseResponse(data)
    }

    // MARK: - Response parsing

    private struct OpenAIResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }
            let message: Message
        }
        let choices: [Choice]
    }

    private struct NutrientPayload: Decodable {
        let food_name: String
        let serving_size: String
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let fiber: Double
        let sugar: Double
    }

    private func parseResponse(_ data: Data) throws -> AnalysisResult {
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = openAIResponse.choices.first?.message.content else {
            throw LLMError.emptyResponse
        }

        // Strip any accidental markdown code fences the model may emit
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw LLMError.parsingFailed(content)
        }

        let payload = try JSONDecoder().decode(NutrientPayload.self, from: jsonData)

        if payload.food_name.lowercased() == "unknown" {
            throw LLMError.noFoodDetected
        }

        return AnalysisResult(
            foodName: payload.food_name,
            servingSize: payload.serving_size,
            nutrients: NutrientInfo(
                calories: payload.calories,
                protein: payload.protein,
                carbs: payload.carbs,
                fat: payload.fat,
                fiber: payload.fiber,
                sugar: payload.sugar
            ),
            confidence: 0.85   // LLM doesn't give a numeric confidence; use a reasonable default
        )
    }
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case missingAPIKey
    case imageEncodingFailed
    case networkError(String)
    case apiError(statusCode: Int, message: String)
    case emptyResponse
    case parsingFailed(String)
    case noFoodDetected

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is not set. Please add it in Settings."
        case .imageEncodingFailed:
            return "Failed to encode the image."
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .apiError(let code, let msg):
            return "API error (\(code)): \(msg)"
        case .emptyResponse:
            return "The LLM returned an empty response."
        case .parsingFailed(let raw):
            return "Failed to parse LLM response: \(raw.prefix(200))"
        case .noFoodDetected:
            return "The LLM could not identify any food in the image."
        }
    }
}
