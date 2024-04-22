//
//  HapticConfigurationView.swift
//  SightSense
//
//  Created by Owen Gregson on 4/6/24.
//

import SwiftUI

struct HapticSettingsView: View {
    @State private var hapticSpeedMultiplier: Double = UserDefaultsManager.shared.double(forKey: "hapticSpeedMultiplier", defaultValue: 1.0)
    @State private var hapticStrengthMultiplier: Double = UserDefaultsManager.shared.double(forKey: "hapticStrengthMultiplier", defaultValue: 1.0)

    var body: some View {
        Form {
            VStack {
                Text("Haptic Speed Multiplier")
                Slider(value: $hapticSpeedMultiplier, in: 0.5...2.5, step: 0.5) {
                } minimumValueLabel: {
                    Text("0.5")
                } maximumValueLabel: {
                    Text("2.5")
                }
                .onChange(of: hapticSpeedMultiplier) { newValue in
                    UserDefaultsManager.shared.set(newValue, forKey: "hapticSpeedMultiplier")
                    VoiceSynthesis.shared.textToSpeech(text: "Haptic Speed Multiplier set to \(String(newValue)).")
                    UIImpactRigidSingleton.shared.impactOccurred()
                }
            }
            VStack {
                Text("Haptic Strength Multiplier")
                Slider(value: $hapticStrengthMultiplier, in: 0.1...1.0, step: 0.1) {
                } minimumValueLabel: {
                    Text("0.1")
                } maximumValueLabel: {
                    Text("1.0")
                }
                .onChange(of: hapticStrengthMultiplier) { newValue in
                    UserDefaultsManager.shared.set(newValue, forKey: "hapticStrengthMultiplier")
                    VoiceSynthesis.shared.textToSpeech(text: "Haptic Strength Multiplier set to \(String(newValue)).")
                    UIImpactRigidSingleton.shared.impactOccurred()
                }
            }
        }
    }
}
