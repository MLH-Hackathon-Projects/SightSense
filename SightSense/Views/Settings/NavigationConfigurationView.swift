//
//  NavigationConfigurationView.swift
//  SightSense
//
//  Created by Owen Gregson on 4/6/24.
//

import SwiftUI

struct NavigationSettingsView: View {
    @State private var enableGamerMode: Bool = UserDefaultsManager.shared.bool(forKey: "enableGamerMode")

    var body: some View {
        Form {
            HStack {
                Text("Enable GamerMode")
                Toggle(isOn: $enableGamerMode) {
                }
                .onChange(of: enableGamerMode) { newValue in
                    UserDefaultsManager.shared.set(newValue, forKey: "enableGamerMode")
                    VoiceSynthesis.shared.textToSpeech(text: "GamerMode turned \(newValue ? "On" : "Off").")
                    UIImpactRigidSingleton.shared.impactOccurred()
                }
            }
        }
    }
}
