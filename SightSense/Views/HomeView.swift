//
//  HomeView.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import SwiftUI

struct HomeView: View {
    
    @AppStorage("hasDoneTutorial") var hasDoneTutorial: Bool = false
    @ObservedObject var microphone: Microphone
    @ObservedObject var locationManager: LocationManager
    @State private var settingsActivation = false
    
    init(){
        self.locationManager = LocationManager.shared
        self.microphone = Microphone.shared
    }
    
    var body: some View {
        ZStack{
            NavigationStack{
                ZStack{
                    GeometryReader { geometry in
                        backgroundGradient
                            .scaledToFill()
                            .edgesIgnoringSafeArea(.all)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    
                    VStack {
                        HStack{
                            UniversalStaticButtonView(display: AnyView(Imagecon(name: "help")), primaryAction: {hasDoneTutorial = false}, secondaryAction: {_ in VoiceSynthesis.shared.textToSpeech(text:"help. tutorial")}, text: "help", primaryColor: Color.pink, secondaryColor: Color.red)
                                .offset(x: 20)
                                .offset(y: 30)
                            Spacer()
                            UniversalStaticButtonView(display: AnyView(Imagecon(name: "settings")), primaryAction: activateSettings, secondaryAction: VoiceSynthesis.shared.textToSpeech, text: "settings", primaryColor: Color.red, secondaryColor: Color.orange)
                                .offset(x: -20)
                                .offset(y: 30)
                        }
                        Spacer()
                        SightSenseSpeakerView(isOn: $microphone.attention, isSpeaking: $microphone.isTalking)
                            .offset(y: -30)
                        Spacer()
                    }
                    .onChange(of: microphone.location){ newValue in
                        if (microphone.location == .settings){
                            activateSettings()
                        }
                    }
                    .navigationDestination(isPresented: $settingsActivation) {
                        SettingsView(isViewShown: $settingsActivation)
                    }
                }
            }
        }
        .onChange(of: locationManager.location){newValue in
            if(locationManager.location == .main){
                if (microphone.location == .settings){
                    activateSettings()
                }else{
                    microphone.updateLocation(newLocation: .main)
                }
            }
        }
        .onDisappear{
            //print("main disappeared")
        }
    }
    private func activateSettings(){
        locationManager.isTabviewEnabled = false
        settingsActivation.toggle()
    }
}
