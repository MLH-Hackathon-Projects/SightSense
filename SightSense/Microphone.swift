//
//  Microphone.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import Foundation
import AVFoundation
import Speech

class Microphone: NSObject, ObservableObject{
    public static let shared = Microphone()
    
    enum viewLocations{
        case main; case textDetection; case textRecognition; case distanceDetection; case objectDetection; case settings; case locateClass
    }
    enum recognizedCommands{
        case main; case textDetection; case textRecognition; case distanceDetection; case objectDetection; case settings; case locateClass; case end
    }
    private var audioEngine: AVAudioEngine!
    private var recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var request = SFSpeechAudioBufferRecognitionRequest()
    private var audioSession = AVAudioSession()
    private var recognizerTask: SFSpeechRecognitionTask?
    var inputNode: AVAudioNode?
    private var voiceSynthesiser = VoiceSynthesis()
    private var audio: AVPlayer!
    private var isCommandFinal = false
    
    private let attentionCommands = ["sightsense", "sight sense", "sight cents", "sigh sense", "sigh cents", "sigh scents", "site sense", "site cents", "site scents", "sight scents", "cite sense", "cite cents", "cite scents", "sison", "sight sins", "sions"]
    
    private let distanceDetectionCommands = ["distance detection", "detect distance", "calculate distance", "calculate the distance", "navigate mode", "navigation mode", "navigation", "this", "is", "section"]
    private let objectRecognitionCommands = ["what is around me", "what's around me", "what objects are around me", "what is next to me", "what's next to me", "what are the objects next to me", "what object is next to me", "what are the objects next to me", "object detection", "detect object", "recognize object", "look for me", "look around me"]
    
    private let textDetectionCommands = ["text detection", "see text", "detect text"]
    private let textRecognitionCommands = ["text recognition", "read text", "recognize text", "read for me"]
    
    private let settingsCommands = ["go to settings", "go to the settings", "navigate to settings", "navigate to the settings", "i need to configure something", "i need to change something"]
    
    private let mainCommands = ["end distance, end navigation, end object, end text, end reading", "stop distance, stop navigation, stop object, stop text, stop reading", "back to main", "back to home", "go home", "go to home", "navigate to home", "navigate to the home"]
    
    private let endSessionCommands = ["end session", "ending session", "terminating session", "terminate session", "shut up", "stop", "nevermind", "never mind", "finished", "finish"]
    
    private let classLocationCommand = ["look for", "find", "locate"]
    
    @Published var attention =  false
    
    @Published var isTalking = false
    @Published var command = true
    @Published var location: viewLocations = .main
    
    
    override init(){
        self.location = .main
        super.init()
        setupRecording()
        //print("microphone setup complete")
    }
    private func setupRecording(){
        
        voiceSynthesiser.synthesizer.delegate = self
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker, .interruptSpokenAudioAndMixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audio session failed to exist")
        }
        //TODO: retardedass apple fix ur dick please
//        do {
//            let audioSession = AVAudioSession.sharedInstance()
//            
//            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetoothA2DP, .allowBluetooth, .defaultToSpeaker])
//            
//            try audioSession.setActive(true)
            //try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//        } catch {
//            print("Failed to configure the AVAudioSession: \(error)")
//        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: AVAudioSession.sharedInstance())

        
        NotificationCenter.default.addObserver(self,
                   selector: #selector(handleInterruption),
                   name: NSNotification.Name.AVAudioEngineConfigurationChange,
                   object: nil
                )
        
        request.shouldReportPartialResults = false
        
        request.requiresOnDeviceRecognition = true
        request.contextualStrings = ["hey sightsense", "hello sightsense", "hi sightsense", "distance detection", "text detection"]
        recognizerTask = recognizer.recognitionTask(with: request, resultHandler: requestHandler)
        setupEngine()
    }
    
    func setupEngine(){
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode!.outputFormat(forBus: 0)
        inputNode!.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do{
            try audioEngine.start()
        } catch {
            print("failed to start audio engine")
        }
    }
    @objc func handleInterruption(notification: Notification) {
        //print("detected an audio interruption")
        setupEngine()
        //print("restarted")
    }
    
    @objc func handleRouteChange(notification: Notification) {
        // Check the route change reason and handle it accordingly
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                return
        }
        print(reason)

        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable:
            // A Bluetooth device was connected or disconnected.
            // Update your UI or logic as needed.
            print("blue dick")
            break
        default: break
        }
    }
    
    private func requestHandler(result: SFSpeechRecognitionResult!, error: Error?){
        if let result = result{
            let command = result.bestTranscription.formattedString.lowercased()
            var commands = command.split(separator: " ")
            let startingPoint = recognizeActivation(message: commands)
            //print(command)
            if (startingPoint != nil || attention == true){
                if (attention == false){
                    commands = cutArray(input: commands, point: (startingPoint ?? 0)+2)
                }
                //print(commands)
                if (commands.count < 1){
                    let url = Bundle.main.url(forResource: "listening_start", withExtension: "wav")
                    audio = AVPlayer.init(url: url!)
                    audio.play()
                    self.attention = true
                    return
                }else{
                    let url = Bundle.main.url(forResource: "listening_end", withExtension: "wav")
                    audio = AVPlayer.init(url: url!)
                    audio.play()
                }
                var lowestNumber = 0
                var recognizedMode: recognizedCommands?
                
                let locateClassCommand = lookForClass(messages: commands)
                if (locateClassCommand != nil && (locateClassCommand ?? 0 < lowestNumber || lowestNumber == 0)){
                    lowestNumber = locateClassCommand!
                    recognizedMode = .locateClass
                }
                
                let distanceCommand = orderedKeyCommand(messages: commands, commands: distanceDetectionCommands)
                if (distanceCommand != nil && (distanceCommand ?? 0 < lowestNumber || lowestNumber == 0)){
                    lowestNumber = distanceCommand!
                    recognizedMode = .distanceDetection
                }
                let objectCommand = orderedKeyCommand(messages: commands, commands: objectRecognitionCommands)
                if (objectCommand != nil && (objectCommand ?? 0 < lowestNumber || lowestNumber == 0)){
                    lowestNumber = objectCommand!
                    recognizedMode = .objectDetection
                }
                
                let textCommand = orderedKeyCommand(messages: commands, commands: textDetectionCommands)
                if (textCommand != nil && (textCommand ?? 0 < lowestNumber || lowestNumber == 0)){
                    lowestNumber = textCommand!
                    recognizedMode = .textDetection
                }
                let readCommand = orderedKeyCommand(messages: commands, commands: textRecognitionCommands)
                if (readCommand != nil && (readCommand ?? 0 < lowestNumber || lowestNumber == 0)){
                    lowestNumber = readCommand!
                    recognizedMode = .textRecognition
                }
                
                let mainCommand = orderedKeyCommand(messages: commands, commands: mainCommands)
                if (mainCommand != nil && (mainCommand ?? 0 < lowestNumber || lowestNumber == 0)){
                    lowestNumber = mainCommand!
                    recognizedMode = .main
                }
                
                let settingsCommand = orderedKeyCommand(messages: commands, commands: settingsCommands)
                if (settingsCommand != nil && (settingsCommand ?? 0 < lowestNumber || lowestNumber == 0)){
                    lowestNumber = settingsCommand!
                    recognizedMode = .settings
                }
                
                let endSessionCommand = orderedKeyCommand(messages: commands, commands: endSessionCommands)
                if (endSessionCommand != nil && (endSessionCommand ?? 0 < lowestNumber || lowestNumber == 0)){
                    lowestNumber = endSessionCommand!
                    recognizedMode = .end
                }
                
                
                if (recognizedMode == nil){
                    self.attention = true
                    microphoneSafeSpeech(message: natualConfused())
                } else {
                    self.attention = false
                    commandLocation(newLocation: recognizedCommandToLocation(recognizedCommand: recognizedMode!))
                }
            }
        }
    }
    
    func orderedKeyCommand(messages: [String.SubSequence], commands: [String]) -> Int?{
        var location: Int?
        for i in 0...messages.count-1{
            for command in commands{
                let parsedCommand = command.split(separator: " ")
                if (messages[i] == parsedCommand[0]){
                    location = i
                    for j in 0...parsedCommand.count-1{
                        if (messages.count - 1 < i+j){
                            location = nil
                            break
                        }
                        if (messages[i+j] != parsedCommand[j]){
                            location = nil
                            //print(parsedCommand[0])
                            break
                        }
                    }
                }
                if (location != nil){
                    break
                }
            }
            if (location != nil){
                break
            }
        }
        return location
    }
    
    func lookForClass(messages: [String.SubSequence]) -> Int?{
        for i in 0..<messages.count{
            for j in 0..<classLocationCommand.count{
                var recognized = true
                let commandSequence = classLocationCommand[j].split(separator: " ")
                for k in 0..<commandSequence.count{
                    if (messages[i+k] != commandSequence[k]){
                        recognized = false
                        break
                    }
                }
                if (recognized == true){
                    return i
                }
            }
        }
        return nil
    }
    
    func recognizeActivation(message: [String.SubSequence]) -> Int?{
        if (message.count < 2){
            if (recognizeKeywordHelper(message: message, location: 0) == true){
                return 0
            }
            return nil
        }
        
        for i in 0...message.count-2{
            if (message[i] == "hello" || message[i] == "hey" || message[i] == "hi"){
                if (recognizeKeywordHelper(message: message, location: i+1)){
                    return i
                }
            }
        }
        return nil
    }
    private func recognizeKeywordHelper(message: [String.SubSequence], location: Int) -> Bool{
        //print(message)
        for i in 0...attentionCommands.count-1{
            let attentionCommand: String = attentionCommands[i]
            let attentionCommandSplit = attentionCommand.split(separator: " ")
            var recognizedCommand = true
            for j in 0...attentionCommandSplit.count-1{
                if (message.count == j+location){
                    recognizedCommand = false
                    break
                }
                if (message[j+location] != attentionCommandSplit[j]){
                    recognizedCommand = false
                }
            }
            if (recognizedCommand == true){
                return true
            }
        }
        return false
    }
    
    private func cutArray(input: [String.SubSequence], point: Int) -> [String.SubSequence]{
        var result: [String.SubSequence] = []
        for i in 0 ..< input.count{
            if (i >= point){
                result.append(input[i])
            }
        }
        return result
    }
    
    func recognizedCommandToLocation(recognizedCommand: recognizedCommands) -> viewLocations{
        switch recognizedCommand{
        case .distanceDetection: microphoneSafeSpeech(message: natualDistanceDetection()); return .distanceDetection
        case .objectDetection: microphoneSafeSpeech(message: natualObjectDetection()); return .objectDetection
        case .textDetection: microphoneSafeSpeech(message: natualTextDetection()); return .textDetection
        case .textRecognition: microphoneSafeSpeech(message: natualTextRecognition()); return .textRecognition
        case .settings: microphoneSafeSpeech(message: natualSettings()); return .settings
        case .main: microphoneSafeSpeech(message: natualMain()); return .main
        case .locateClass: microphoneSafeSpeech(message: natuallookForClass()); return .locateClass
        default: microphoneSafeSpeech(message: natualEndingSession()); return location
        }
    }
    
    func microphoneSafeSpeech(message: String){
        inputNode?.engine?.pause()
        voiceSynthesiser.textToSpeech(text: message)
        isTalking = true
    }
    func natualSelecter(){
        
    }
    
    func natualConfused() -> String{
        switch Int.random(in: 1...10){
        case 1: return "Can you please repeat that?"
        case 2: return "Could you repeat a little louder, please?"
        case 3: return "I'm sorry, I didn't hear you."
        case 4: return "Please can you tell me again?"
        case 5: return "I didn't quite catch what you said, can you please repeat that?"
        case 6: return "Apologies, I didn't catch what you said, can you tell me again?"
        case 7: return "I apologize, but I'm having difficulty understanding what you just said. Could you please say it in a different way?"
        case 8: return "Pardon me, I missed what you just said"
        case 9: return "I apologize, but I didn't hear what you just said."
        default: return "I'm sorry, I didn't understand. Can you please repeat that?"
        }
    }
    func natualEndingSession() -> String{
        switch Int.random(in: 1...5){
        case 1: return "Ok."
        case 2: return "Sure."
        case 3: return "No problem."
        case 4: return "Got it."
        default: return "Ending session now."
        }
    }
    func natualDistanceDetection() -> String{
        switch Int.random(in: 1...5){
        case 1: return "Ok, navigation enabled!"
        case 2: return "Sure, activating navigation."
        case 3: return "Will do, enabling navigation!"
        case 4: return "Activating navigation mode."
        default: return "No problem, Navigation mode is now on."
        }
    }
    func natualObjectDetection() -> String{
        switch Int.random(in: 1...5){
        case 1: return "Ok, detecting objects in the navigation page."
        case 2: return "Sure, navigating and detecting objects."
        case 3: return "Will do, detecting objects."
        case 4: return "Activating object detection."
        default: return "No problem, detecting objects."
        }
    }
    func natualTextDetection() -> String{
        switch Int.random(in: 1...5){
        case 1: return "ok, text detection enabled"
        case 2: return "Sure, activating text detection."
        case 3: return "Will do, enabling text detection!"
        case 4: return "Activating text detection mode."
        default: return "No problem, text detection mode is now on."
        }
    }
    func natualTextRecognition() -> String{
        switch Int.random(in: 1...5){
        case 1: return "Ok, reading text!"
        case 2: return "Sure, detecting and reading text."
        case 3: return "Will do, reading text!"
        case 4: return "Reading text."
        default: return "No problem, reading text."
        }
    }
    func natualSettings() -> String{
        switch Int.random(in: 1...5){
        case 1: return "Ok, navigating to the settings menu!"
        case 2: return "Sure, going to settings."
        case 3: return "Will do, navigating to settings!"
        case 4: return "Going to settings."
        default: return "No problem, going to the settings menu."
        }
    }
    func natualMain() -> String{
        switch Int.random(in: 1...5){
        case 1: return "Ok, going back to home!"
        case 2: return "Sure, going to home."
        case 3: return "Will do, navigating to home!"
        case 4: return "Going to home."
        default: return "No problem, navigating home."
        }
    }
    func natualUnable() -> String{
        return "you are already at your desired location"
    }
    
    func natuallookForClass() -> String{
        switch Int.random(in: 1...5){
        case 1: return "Ok, looking for the object now!"
        case 2: return "Sure, looking for the object."
        case 3: return "Will do, detecting the object!"
        case 4: return "looking for the object."
        default: return "No problem, detecting the object."
        }
    }
    
    
    func stop(){
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
        recognizerTask?.cancel()
        recognizerTask?.finish()
        recognizerTask = nil
        inputNode = nil
    }
    func commandLocation(newLocation: viewLocations){
        command = true
        location = newLocation
    }
    func updateLocation(newLocation: viewLocations){
        command = false
        location = newLocation
    }
}

extension Microphone: AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        try? inputNode?.engine?.start()
        isTalking = false
        if (attention){
            let url = Bundle.main.url(forResource: "listening_start", withExtension: "wav")
            audio = AVPlayer.init(url: url!)
            audio.play()
        }
    }
}
