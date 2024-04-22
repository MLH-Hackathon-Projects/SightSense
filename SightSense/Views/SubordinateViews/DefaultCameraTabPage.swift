////
////  DefaultCameraTabPage.swift
////  SightSense
////
////  Created by Peter Zhao on 4/6/24.
////
//
//import SwiftUI
//
//struct DefaultCameraTabPage: View {
//    @StateObject var camera: CameraBase
//    @ObservedObject var microphone: Microphone
//    @StateObject var buttonProperties: ButtonModifier
//    @ObservedObject var locationManager: LocationManager
//    
//    init(microphone: Microphone, locationManager: LocationManager){
//        self.microphone = microphone
//        self.locationManager = locationManager
//        _buttonProperties = StateObject(wrappedValue: ButtonModifier(bg1: Color.accentColor, bg2: Color.green, fg: Color.white, text: "Read", secondaryBg1: Color.red, secondaryBg2: Color.blue, secondaryFg: Color.white, secondaryText: "Stop"))
//    }
//    
//    var body: some View {
//        
//        .overlay(alignment: .center){
//            VStack{
//                buttonsView()
//            }
//        }
//        
//        .navigationBarHidden(true)
//        .statusBar(hidden: true)
//        
//        .onChange(of: locationManager.location){newValue in
//            if(locationManager.location == .text){
//                print("text appeared")
//                
//                camera.syncStartCamera()
//                camera.isToggled = true
//                
//                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//                if (microphone.location == .textRecognition){
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        photoButtonHandler()
//                    }
//                }
//                microphone.updateLocation(newLocation: .textDetection)
//            }
//        }/*
//        .onAppear{
//            if(locationManager.location == .text){
//                print("text appeared")
//                
//                camera.syncStartCamera()
//                camera.isToggled = true
//                
//                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//                if (microphone.location == .textRecognition){
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        photoButtonHandler()
//                    }
//                }
//                microphone.updateLocation(newLocation: .textDetection)
//            }
//        }*/
//        .onDisappear{
//            if (!buttonProperties.primaryState){
//                buttonProperties.toggleAllProperties()
//            }
//            camera.isToggled = false
//            print("text disappeared")
//            endEverything()
//        }
//
//    }
//    
//    func buttonsView() -> some View {
//        VStack {
//            StaticButtonViewWithIcon(display: AnyView(ScalableImageIcon(name: "exit_page", width: 60, height: 60)), primaryAction: revertToRoot, secondaryAction: VoiceSynthesizerSingleton.shared.textToSpeech, width: 350, height: 100, text: "Back", bg1: Color(UIColor(hexString: "#EE6666")), bg2: Color(UIColor(hexString: "#a36565")), fg: Color.white, corner: 15)
//            Spacer()
//            DynamicButtonViewWitIcon(display1: AnyView(ScalableImageIcon(name: "activate_text", width: 50, height: 50)), display2: AnyView(ScalableImageIcon(name: "stop_action", width: 50, height: 50)), primaryAction: photoButtonHandler, secondaryAction: VoiceSynthesizerSingleton.shared.textToSpeech, width: 350, height: 100, text: $buttonProperties.text, bg1: $buttonProperties.bg1, bg2: $buttonProperties.bg2, fg: $buttonProperties.fg, onPrimaryView: $buttonProperties.primaryState, corner: 20)
//                .offset(y: -80)
//        }
//    }
//    func revertToRoot(){
//        microphone.commandLocation(newLocation: .main)
//    }
//    func endEverything(){
//        camera.stopCamera()
//        camera.stopVoice()
//    }
//    func photoButtonHandler(){
//        if (buttonProperties.primaryState){
//            camera.takePhoto()
//            microphone.location = .textDetection
//        } else {
//            camera.stopVoice()
//        }
//        microphone.location = .textDetection
//    }
//
//}
//
//#Preview {
//    DefaultCameraTabPage()
//}
