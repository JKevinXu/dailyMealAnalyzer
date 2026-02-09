//
//  MealAnalyzerApp.swift
//  MealAnalyzer
//
//  Created by KX on 2026/2/9.
//

import SwiftUI
import SwiftData

@main
struct MealAnalyzerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: MealRecord.self)
    }
}
