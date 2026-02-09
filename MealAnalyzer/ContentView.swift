//
//  ContentView.swift
//  MealAnalyzer
//
//  Created by KX on 2026/2/9.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AnalyzeView()
                .tabItem {
                    Label("Analyze", systemImage: "fork.knife.circle.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
        .tint(.green)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MealRecord.self, inMemory: true)
}
