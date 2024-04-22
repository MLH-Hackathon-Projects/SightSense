//
//  SightSenseSpeakerView.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import SwiftUI

struct SightSenseSpeakerView: View {
    @Binding var isOn: Bool
    @Binding var isSpeaking: Bool
    @State var isAnimating: Bool = false
    @State var primaryColor = Color(UIColor(hexString: "#e4b1d8"))
    @State var secondaryColor = Color(UIColor(hexString: "#a8e1dd"))
    
    var body: some View {
        resizablePolygon(polygonWidth: isAnimating ? 200 : 150, polygonHeight: isAnimating ? 200 : 150, cornerRadius: isAnimating ? 30 : 26, logoWidth: isAnimating ? 120 : 80, logoHeight: isAnimating ? 120 : 80)
        
            .contentShape(Rectangle())
            //.padding(500)
            .background(Color.clear)
            
            .foregroundStyle(LinearGradient(colors: [primaryColor, secondaryColor], startPoint: .topTrailing, endPoint: .bottomLeading))
            .animation(.interpolatingSpring(stiffness: 50, damping: 5), value: isAnimating)
        
            .onTapGesture {
                UIImpactHeavySingleton.shared.impactOccurred()
                isOn.toggle()
            }
            .onLongPressGesture(minimumDuration: 1) {
                UINotificationSingleton.shared.notificationOccurred(.success)
                VoiceSynthesis.shared.textToSpeech(text: "voice assistant.")
            } onPressingChanged: { value in
                let temp = primaryColor
                self.primaryColor = secondaryColor
                self.secondaryColor = temp
            }
            .onChange(of: isOn){ newValue in
                if (isOn || isSpeaking){
                    self.isAnimating = true
                }else{
                    self.isAnimating = false
                }
            }
            .onChange(of: isSpeaking){ newValue in
                if (isOn || isSpeaking){
                    self.isAnimating = true
                }else{
                    self.isAnimating = false
                }
            }
    }
}

