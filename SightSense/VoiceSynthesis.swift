//
//  VoiceOperation.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import Foundation
import AVFoundation
import MLKit

class VoiceSynthesis: NSObject{
    public static let shared = VoiceSynthesis()
    
    let synthesizer = AVSpeechSynthesizer()
    private let userMadeSettings = UserDefaults.standard
    private var translationOptions: TranslatorOptions?
    private var translator: Translator?

    override init(){
        super.init()
        setUpTranslation()
    }
    
    func setUpTranslation(){
        translationOptions = TranslatorOptions(sourceLanguage: langCodeToLang(langCode: userMadeSettings.string(forKey: "readingLanguage") ?? "english"), targetLanguage: langCodeToLang(langCode: userMadeSettings.string(forKey: "outputLanguage") ?? "english"))
        
        translator = Translator.translator(options: translationOptions!)
        translator?.downloadModelIfNeeded(with: ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)) { error in
            guard error == nil else { print("failed to download model"); return }
        }
    }
    
    func stopVoice(){
        synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        
    }
    
    func textToSpeech(text: String) {
        if (userMadeSettings.string(forKey: "outputLanguage") ?? "en" != userMadeSettings.string(forKey: "readingLanguage")?.split(separator: "-")[0] ?? "en"){
            translator?.downloadModelIfNeeded(with: ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)) { error in
                guard error == nil else { print("failed to download model"); return }
                self.translator?.translate(text) { translatedText, error in
                    guard error == nil, let translatedText = translatedText else { return }
                    print(translatedText)
                    print(ModelManager.modelManager().downloadedTranslateModels)
                    self.speakWithSettings(text: translatedText, urgent: true)
                }
            }
        } else {
            speakWithSettings(text: text)
        }
    }
    
    func speakWithSettings(text: String, urgent: Bool = true){
        if (synthesizer.isSpeaking) {
            if (urgent){
                stopVoice()
            }else{
                synthesizer.pauseSpeaking(at: .immediate)
            }
        }
        internalSpeechWithSettings(text: text)
    }
    
    private func internalSpeechWithSettings(text: String){
        let utterance = AVSpeechUtterance(string: text)
        var voiceToUse: AVSpeechSynthesisVoice!
        var voiceName: String
        var speedSetting: Float = 0.47
        voiceName = String(userMadeSettings.string(forKey: "selectedVoice") ?? "Samantha")
        if  (userMadeSettings.float(forKey: "voiceSpeed") != 0) {
            speedSetting = (round(userMadeSettings.float(forKey: "voiceSpeed"))-1)/23.53+0.30
        }
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            if voice.name == voiceName {
                voiceToUse = voice
                break
            }
        }
        utterance.voice = voiceToUse
        utterance.rate = speedSetting
        utterance.volume = 100
        self.synthesizer.speak(utterance)
    }
    
    private func langCodeToLang(langCode: String) -> TranslateLanguage{
        let langCodeShort = langCode.split(separator: "-")[0]
        var lang: TranslateLanguage
        switch langCodeShort{
        case "en": lang = .english
        default: lang = .english
        }
        return lang
    }
}
