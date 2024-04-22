//
//  TextConfigurationView.swift
//  SightSense
//
//  Created by Owen Gregson on 4/6/24.
//

import SwiftUI

struct TextDetectionSettingsView: View {
    
    let detectionModes = ["Fast", "Balanced", "Accurate"]
    
    @State private var selectedMode: String = UserDefaultsManager.shared.string(forKey: "textDetectionMode", defaultValue: "Balanced")

    var body: some View {
        Form {
            VStack {
                Text("Text Detection Mode")
                Picker("Text Detection Mode", selection: $selectedMode) {
                    ForEach(detectionModes, id: \.self) { mode in
                        Text(mode).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedMode) { newValue in
                    UserDefaultsManager.shared.set(newValue, forKey: "textDetectionMode")
                    VoiceSynthesis.shared.textToSpeech(text: "Text Detection Mode set to \(String(newValue)).")
                    UIImpactRigidSingleton.shared.impactOccurred()
                }
            }
        }
    }
}
