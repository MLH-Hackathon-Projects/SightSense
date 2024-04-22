//
//  GlobalDetectionConfigurationView.swift
//  SightSense
//
//  Created by Owen Gregson on 4/6/24.
//

import SwiftUI

struct GlobalDetectionSettingsView: View {
    @State private var showCameraPreview: Bool = UserDefaultsManager.shared.bool(forKey: "showCameraPreview")

    var body: some View {
        Form {
            HStack {
                Toggle(isOn: $showCameraPreview) {
                    Text("Show Camera Preview")
                }
                .onChange(of: showCameraPreview) { newValue in
                    UserDefaultsManager.shared.set(newValue, forKey: "showCameraPreview")
                    VoiceSynthesis.shared.textToSpeech(text: "Camera Preview turned \(newValue ? "On" : "Off").")
                    UIImpactRigidSingleton.shared.impactOccurred()
                }
            }
        }
    }
}
