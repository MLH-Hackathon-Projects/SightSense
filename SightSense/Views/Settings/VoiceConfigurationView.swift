//
//  VoiceSynthesisConfigurationView.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//
import SwiftUI
import AVFoundation

struct VoiceConfigurationView: View {
    class Voice: NSObject, ObservableObject{
        @Published var name: String = "Samantha"
        @Published var voice: AVSpeechSynthesisVoice = AVSpeechSynthesisVoice.speechVoices()[0]
        
        init(name: String){
            super.init()
            updateVoice(name: name)
        }
        
        func updateVoice(name: String){
            let voice = findVoiceByName(name: name)
            if (voice == nil){
                self.name = "Samantha"
                self.voice = findVoiceByName(name: self.name)!
            }else{
                self.name = name
                self.voice = voice!
            }
        }
        
        private func findVoiceByName(name: String) -> AVSpeechSynthesisVoice?{
            for voice in AVSpeechSynthesisVoice.speechVoices(){
                if (voice.name == name) {
                    return voice
                }
            }
            return nil
        }
    }
    
    @StateObject private var voice: Voice
    @State private var voiceSpeed: Double = UserDefaultsManager.shared.double(forKey: "voiceSpeed", defaultValue: 5)
    @State private var voiceVolume: Double = UserDefaultsManager.shared.double(forKey: "voiceVolume", defaultValue: 100)
    @State private var totalVoices: [String] = []
    private let blackListedVoices = ["Shelley", "Grandpa", "Grandma", "Sandy", "Rocko", "Eddy", "Reed", "Flo", "Daniel"]
    
    init(){
        let voiceName = UserDefaultsManager.shared.string(forKey: "selectedVoice", defaultValue: "Samantha")
        self._voice = StateObject(wrappedValue: Voice(name: voiceName))
        totalVoices = getVoices()
    }
    
    var body: some View {
        Form {
            Picker("Select a voice", selection: $voice.name) {
                ForEach(totalVoices, id: \.self) { eachVoice in
                    Text(eachVoice)
                }
            }
            VStack{
                Text("Voice Speed")
                DebouncedSteppedSlider(value: $voiceSpeed)
                .onChange(of: voiceSpeed) { newValue in
                    UserDefaultsManager.shared.set(newValue, forKey: "voiceSpeed")
                    VoiceSynthesis.shared.textToSpeech(text: "Voice Speed set to \(String(newValue)).")
                    UIImpactRigidSingleton.shared.impactOccurred()
                }
            }
            VStack{
                Text("Voice Volume")
                Slider(value: $voiceVolume, in: 1...100, step: 1) {
                } minimumValueLabel: {
                    Text("1")
                } maximumValueLabel: {
                    Text("100")
                }
                .onChange(of: voiceVolume) { newValue in
                    UserDefaultsManager.shared.set(newValue, forKey: "voiceVolume")
                    VoiceSynthesis.shared.textToSpeech(text: "Voice Volume set to \(String(newValue))%.")
                    UIImpactRigidSingleton.shared.impactOccurred()
                }
            }
        }
        
        .onAppear{
            voiceSpeed = UserDefaultsManager.shared.double(forKey: "voiceSpeed", defaultValue: 5)
            voiceVolume = UserDefaultsManager.shared.double(forKey: "voiceVolume", defaultValue: 100)
            let voiceName = UserDefaultsManager.shared.string(forKey: "selectedVoice", defaultValue: "Samantha")
            voice.updateVoice(name: voiceName)
            totalVoices = getVoices()
        }
        .onChange(of: voice.name){ newValue in
            voice.updateVoice(name: newValue)
            UserDefaultsManager.shared.set(newValue, forKey: "selectedVoice")
            VoiceSynthesis.shared.textToSpeech(text: "New voice set to \(String(newValue)).")
            UIImpactRigidSingleton.shared.impactOccurred()
        }
    }
    
    private func getVoices() -> [String]{
        var result: [String] = []
        let totalVoices = AVSpeechSynthesisVoice.speechVoices()
        for i in 0..<totalVoices.count{
            var isIncluded = false
            let voice = totalVoices[i].name
            for j in 0..<blackListedVoices.count{
                if (voice == blackListedVoices[j]){
                    isIncluded = true
                    break
                }
            }
            if (!isIncluded){
                result.append(voice)
            }
        }
        return result
    }
}
