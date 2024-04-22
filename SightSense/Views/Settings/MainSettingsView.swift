//
//  MainSettings.swift
//  SightSense
//
//  Created by Owen Gregson on 4/6/24.
//

import SwiftUI

struct SettingsView: View {
    
    let languages: [String] = ["English", "简单中文", "pусский"]
    let voices: [String] = ["Samantha (Enhanced)", "Gordon", "Arthur"]
    let detectionModes: [String] = ["Fast", "Default", "Accurate"]
    
    private let voiceSynthesiser: VoiceSynthesis
    @ObservedObject private var microphone: Microphone
    private var settingsByCategory: [SettingsCategory: [Setting]]
    @State var isViewExisting = true
    @Binding var isViewShown: Bool
    
    init(isViewShown: Binding<Bool>){
        self.voiceSynthesiser = VoiceSynthesis()
        self.microphone = Microphone.shared
        self._isViewShown = isViewShown
        settingsByCategory = Dictionary(grouping: settings, by: { $0.category })
    }
    
    let settings: Array<Setting> = [
    
    // CATEGORY: Account
    Setting(title: "Personal Details", category: .Account, menu: .PersonalDetails, color: .cyan, imageName: "person.crop.circle.fill"),
    Setting(title: "Change Email", category: .Account, menu: .Email, color: .cyan, imageName: "envelope.circle.fill"),
    Setting(title: "Change Password", category: .Account, menu: .Password, color: .cyan, imageName: "lock.circle.fill"),

    // CATEGORY: Language Settings
    Setting(title: "Detect Language", category: .LanguageSettings, menu: .LanguageInput, color: .green, imageName: "bubble.left.circle.fill"),
    Setting(title: "Output Language", category: .LanguageSettings, menu: .LanguageOutput, color: .green, imageName: "bubble.right.circle.fill"),

    // CATEGORY: Voice Assistant
    Setting(title: "Voice Configuration", category: .VoiceAssistantSettings, menu: .VoiceConfiguration, color: .orange, imageName: "waveform.circle.fill"),
    
    // CATEGORY: Detection Settings
    Setting(title: "Global Settings", category: .DetectionSettings, menu: .GlobalSettings, color: .accentColor, imageName: "link.circle.fill"),
    Setting(title: "Text Detection", category: .DetectionSettings, menu: .TextSettings, color: .accentColor, imageName: "book.circle.fill"),
    Setting(title: "Navigation", category: .DetectionSettings, menu: .NavigationSettings, color: .accentColor, imageName: "location.circle.fill"),

    // CATEGORY: Haptic Settings
    Setting(title: "Haptic Settings", category: .HapticsSettings, menu: .HapticSettings, color: .indigo, imageName: "iphone.radiowaves.left.and.right.circle.fill")
    ]

    var body: some View {
        NavigationStack {
            List {
                // Sort settings into their categories
                ForEach(Array(settingsByCategory.keys.sorted(by: { $0.sortOrder < $1.sortOrder })), id: \.self) { category in
                    Section(header: Text(category.displayName)) {
                        ForEach(settingsByCategory[category] ?? [], id: \.self) { setting in
                            SettingsCategoryLink(destination: AnyView(RootSettingView(viewToDisplay: setting.menu)), iconView: AnyView(SettingImage(color: setting.color, imageName: setting.imageName)), displayName: setting.title)
                        }
                    }
                }
            }
        }
        .onAppear{
            print("settings is spawning")
            isViewExisting = true
            microphone.updateLocation(newLocation: .settings)
        }
        .onDisappear{
            print("settings is despawning")
            isViewExisting = false
        }
        .onChange(of: isViewExisting){ newValue in
            

        }
    }
}

enum SettingsCategory {
    case Account
    case LanguageSettings
    case VoiceAssistantSettings
    case DetectionSettings
    case HapticsSettings
    
    var displayName: String {
        switch self {
            case .Account:
                return "Account"
            case .LanguageSettings:
                return "Language Settings"
            case .VoiceAssistantSettings:
                return "Voice Assistant"
            case .DetectionSettings:
                return "Detection Settings"
            case .HapticsSettings:
                return "Haptic Settings"
        }
    }
    
    var sortOrder: Int {
        switch self {
            case .Account:
                return 1
            case .LanguageSettings:
                return 2
            case .VoiceAssistantSettings:
                return 3
            case .DetectionSettings:
                return 4
            case .HapticsSettings:
                return 5
        }
    }
}

enum SettingsMenu {
    
    // CATEGORY: Account
    case PersonalDetails
    /* First Name (Short Text) [Default: "SightSense"] */
    /* Last Name (Short Text) [Default: "User"] */
    /* Email (Email) [not editable] [Default: "business@sightsense.ai"] */
    case Email
    /* Leave this one as an example view for now*/
    case Password
    /* Leave this one as an example view for now*/
    
    // CATEGORY: Language Settings
    case LanguageInput
    /* Language Picker View (see image) [Default: English] */
    case LanguageOutput
    /* Language Picker View (see image) [Default: English] */
    
    // CATEGORY: Voice Settings
    case VoiceConfiguration
    /* Select a voice: (Dropdown: voicesList) */
    /* Voice Speed: (Integer Slider: 1-10 [Default: 5]) */
    /* Voice Volume: (Integer Slider 1-100 [Default 100]) */
    
    // CATEGORY: Detection Settings
    case GlobalSettings
    /* Show Camera Preview (Toggle: On/Off [Default: On]) */
    case TextSettings
    /* Text Detection Mode (Dropdown: "Fast," "Balanced," "Accurate" [Default: Balanced]) */
    case NavigationSettings
    /* Enable GamerMode (Toggle: On/Off [Default: Off]) */
    
    // CATEGORY: Haptic Settings
    case HapticSettings
    /* Haptic Speed Multiplier (Float/Double Slider [Step .5] [Default: 1.0]: 0.5-2.5) */
    /* Haptic Strength Multiplier (Float/Double Slider [Step .1] [Default: 1.0] 0.1-1.0) */
}

struct RootSettingView: View {
    let viewToDisplay: SettingsMenu
    var body: some View {
        switch viewToDisplay {
            case .PersonalDetails:
                PersonalDetailsView()
            case .Email:
                EmailSwitchView()
            case .Password:
                PasswordSwitchView()
            case .LanguageInput:
                PickInputLanguageView()
            case .LanguageOutput:
                PickOutputLanguageView()
            case .VoiceConfiguration:
                VoiceConfigurationView()
            case .GlobalSettings:
                GlobalDetectionSettingsView()
            case .TextSettings:
                TextDetectionSettingsView()
            case .NavigationSettings:
                NavigationSettingsView()
            case .HapticSettings:
                HapticSettingsView()
        }
    }
}

struct Setting: Hashable {
  let title: String
  let category: SettingsCategory
  let menu: SettingsMenu
  let color: Color
  let imageName: String
}

struct SettingImage: View {
  let color: Color
  let imageName: String
  
  var body: some View {
    Image(systemName: imageName)
      .resizable()
      .foregroundStyle(color)
      .frame(width: 25, height: 25)
  }
}
