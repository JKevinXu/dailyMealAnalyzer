//
//  SettingsView.swift
//  MealAnalyzer
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("openai_api_key") private var apiKey: String = ""
    @State private var showingKey = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - OpenAI API Key
                Section {
                    HStack {
                        if showingKey {
                            TextField("sk-...", text: $apiKey)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-...", text: $apiKey)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }

                        Button {
                            showingKey.toggle()
                        } label: {
                            Image(systemName: showingKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("OpenAI API Key")
                } footer: {
                    Text("Required for meal analysis. Your key is stored locally on this device and never shared.")
                }

                // MARK: - About
                Section("About") {
                    HStack {
                        Text("Analysis Engine")
                        Spacer()
                        Text("GPT-4o Vision")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
