//
//  WelcomeManager.swift
//  SightSense
//
//  Created by Owen Gregson on 4/6/24.
//

import Foundation
import Foundation
import AVFoundation

class WelcomeManager: NSObject, ObservableObject {
    
    enum step: CaseIterable{
        case welcome; case main; case distance; case text; case complete;
    }
    
    private let voiceSynthesizer = VoiceSynthesis()
    @Published var progress: step
    @Published var isSpeaking = false
    
    override init(){
        progress = .welcome
        super.init()
        voiceSynthesizer.synthesizer.delegate = self
        sayStep(goToNext: true)
        sayStep(goToNext: false)
    }
    func nextStep(){
        progress = progress.next()
        sayStep(goToNext: false)
    }
    
    func sayStep(goToNext:Bool) {
        switch progress {
            case .welcome:
                welcomeSpeech()
            case .main:
                mainSpeech()
            case .distance:
                distanceSpeech()
            case .text:
                textSpeech()
            case .complete:
                doneSpeech()
            }
        if(goToNext) {
            progress = progress.next()
        }
    }
    
    func welcomeSpeech(){
        isSpeaking = true
        voiceSynthesizer.textToSpeech(text: "Welcome to SightSense. Before we get started, let's take a quick walkthrough of the app's basic features.")
    }
    func mainSpeech(){
        isSpeaking = true
        voiceSynthesizer.textToSpeech(text: "This is the home screen. On this page, you can access me, your voice assistant, to navigate to other pages. On the bottom of the page, there is a navigation bar with three icons. On the left, there is the home page, the one you are in now. In the center, there is the navigation page. Finally, on the right, is the text detection page. Instead of using the voice assistant, you may swipe left or right to navigate pages in that order. Alternatively, you may also press the icons from the home page to navigate. If you aren't sure which button you are about to press, hold your finger down and the voice assistant will read it aloud for you. For now, when you access new pages, they won't work until we finish the tutorial. First, try entering the navigation page using any method you like.")
    }
    func distanceSpeech(){
        isSpeaking = true
        voiceSynthesizer.textToSpeech(text: "Great job! You're now on the Navigation page. Here, you can swipe up or down to change the navigation mode. There are three modes, which we'll list from top to bottom. The top mode is object detection, where you can assess objects around you, their direction from you, and how far away they are. In the middle, you have a scene description. This will give you a detailed overview of your surroundings such as the location of a road, sidewalk, street crossing, or other large elements near you. Lastly, the bottom mode is raw distance detection, which you can use as a virtual cane in order to sense the distance between yourself and nearby surfaces. Distance mode will provide haptic feedback that gets stronger as you approach surfaces. In other modes, pressing the bottom half of the screen will take a snapshot and provide you the details requested. Now that we've gone over the Navigation page, try making your way to the next page, text detection.")
    }
    func textSpeech() {
        isSpeaking = true
        voiceSynthesizer.textToSpeech(text: "Well done! Welcome to the text detection page. While on this page, you will receive live haptic feedback when text is detected within the camera view frame. Once some text is detected, you can press the bottom half of the screen to read the text aloud. Any text will work, such as paper documents, writing, and even computer screens. Now, head back to the home page to wrap up our tutorial.")
    }
    func doneSpeech(){
        isSpeaking = true
        voiceSynthesizer.textToSpeech(text: "Good job. Don't worry if all of the information presented seems complicated, it will just take some getting used to. After using SightSense for a while, you'll become adjusted to the features and feel more empowered than ever. If you ever need me, just say, Hey SightSense, and make your request. Welcome to SightSense!")
    }
}
extension WelcomeManager: AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}

extension CaseIterable where Self: Equatable {
func previous() -> Self {
    let all = Self.allCases
    var idx = all.firstIndex(of: self)!
    if idx == all.startIndex {
        let lastIndex = all.index(all.endIndex, offsetBy: -1)
        return all[lastIndex]
    } else {
        all.formIndex(&idx, offsetBy: -1)
        return all[idx]
    }
}
func next() -> Self {
    let all = Self.allCases
    let idx = all.firstIndex(of: self)!
    let next = all.index(after: idx)
    return all[next == all.endIndex ? all.startIndex : next]
    }
}
