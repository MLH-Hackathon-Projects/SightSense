//
//  ButtonViews.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import Foundation
import SwiftUI
import PolyKit

let backgroundGradient = LinearGradient(
    colors: [Color(UIColor(hexString: "#313351")), Color(UIColor(hexString: "#1F2134"))],
    startPoint: .top, endPoint: .bottom)

struct BaseButtonView: View {
    let width: CGFloat
    let height: CGFloat
    let text: String
    let bg1: Color
    let bg2: Color
    let fg: Color
    let corner: CGFloat
    var body: some View {
        ZStack{
            LinearGradient(colors: [bg1, bg2], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            Text(text)
        }
        .frame(width: self.width, height: self.height, alignment: .center)
        .foregroundColor(self.fg)
        .cornerRadius(self.corner)
    }
}

struct DynamicButtonView: View {
    let primaryAction: () -> Void
    let secondaryAction: (String) -> Void
    let width: CGFloat
    let height: CGFloat
    @Binding var text: String
    @Binding var bg1: Color
    @Binding var bg2: Color
    @Binding var fg: Color
    let corner: CGFloat
    var body: some View {
        BaseButtonView(width: width, height: height, text: text, bg1: bg1, bg2: bg2, fg: fg, corner: corner)
        .onTapGesture {
            primaryAction()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        .onLongPressGesture(minimumDuration: 1) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            secondaryAction(text)
        } onPressingChanged: { value in
            let temp = bg1
            self.bg1 = self.bg2
            self.bg2 = temp
        }
    }
}

struct StaticButtonView: View {
    let primaryAction: () -> Void
    let secondaryAction: (String) -> Void
    let width: CGFloat
    let height: CGFloat
    let text: String
    @State var bg1: Color
    @State var bg2: Color
    let fg: Color
    let corner: CGFloat
    var body: some View {
        BaseButtonView(width: width, height: height, text: text, bg1: bg1, bg2: bg2, fg: fg, corner: corner)
        .onTapGesture {
            primaryAction()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        .onLongPressGesture(minimumDuration: 1) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            secondaryAction(text)
        } onPressingChanged: { value in
            let temp = bg1
            self.bg1 = self.bg2
            self.bg2 = temp
        }
        .padding()
    }
}

struct StaticButtonViewWithIcon: View {
    let display: AnyView
    let primaryAction: () -> Void
    let secondaryAction: (String) -> Void
    let width: CGFloat
    let height: CGFloat
    let text: String
    @State var bg1: Color
    @State var bg2: Color
    let fg: Color
    let corner: CGFloat
    var body: some View {
        ZStack{
            ZStack{
                Rectangle()
                    .fill(bg1)
                    .onTapGesture {
                        primaryAction()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    .onLongPressGesture(minimumDuration: 1) {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        secondaryAction(text)
                    } onPressingChanged: { value in
                        let temp = bg1
                        self.bg1 = self.bg2
                        self.bg2 = temp
                    }
                display
            }
            .frame(width: self.width, height: self.height, alignment: .center)
            .foregroundColor(self.fg)
            .cornerRadius(self.corner)
            .padding()
        }
    }
}

struct DynamicButtonViewWitIcon: View {
    let display1: AnyView
    let display2: AnyView
    let primaryAction: () -> Void
    let secondaryAction: (String) -> Void
    let width: CGFloat
    let height: CGFloat
    @State var isAvaliable = true
    @Binding var text: String
    @Binding var bg1: Color
    @Binding var bg2: Color
    @Binding var fg: Color
    @Binding var onPrimaryView: Bool
    
    let corner: CGFloat
    var body: some View {
        ZStack{
            ZStack{
                Rectangle()
                    .fill(bg1)
                    .onTapGesture {
                        if (isAvaliable){
                            primaryAction()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            isAvaliable = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                isAvaliable = true
                            }
                        }
                    }
                    .onLongPressGesture(minimumDuration: 1) {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        secondaryAction(text)
                    } onPressingChanged: { value in
                        let temp = bg1
                        self.bg1 = self.bg2
                        self.bg2 = temp
                    }
                if (onPrimaryView){
                    display1
                }else{
                    display2
                }
            }
            .frame(width: self.width, height: self.height, alignment: .center)
            .foregroundColor(self.fg)
            .cornerRadius(self.corner)
            .padding()
        }
    }
}


struct NavigationLinkView: View {
    let destination: AnyView
    let longPressAction: (String) -> Void
    let width: CGFloat
    let height: CGFloat
    let text: String
    let bg1: Color
    let bg2: Color
    let fg: Color
    let corner: CGFloat
    @Binding var activationBinding: Bool
    
    private func activateButton(){
        activationBinding.toggle()
        
    }
    var body: some View {
        StaticButtonView(primaryAction: activateButton, secondaryAction: longPressAction, width: width, height: height, text: text, bg1: bg1, bg2: bg2, fg: fg, corner: corner)
        .navigationDestination(isPresented: $activationBinding) {
            destination
        }
        
    }
}

struct SettingsCategoryLink: View {
    let destination: AnyView
    let iconView: AnyView
    @State var displayName: String
    @State var activationBinding = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            activationBinding.toggle()
            VoiceSynthesis.shared.textToSpeech(text: "navigating to \(displayName).")
        }) {
            HStack {
                iconView
                Text(displayName)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.forward")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .foregroundColor(.gray)
            }
            .background(isPressed ? Color.gray.opacity(0.3) : Color.clear)
        }
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged({ _ in
            isPressed = true
        }).onEnded({ _ in
            isPressed = false
        }))
        .simultaneousGesture(LongPressGesture().onEnded { _ in
            //print("Long press detected")
            VoiceSynthesis.shared.textToSpeech(text: displayName)
        })
        .navigationDestination(isPresented: $activationBinding) {
            destination
        }
    }
}


class ButtonModifier:  NSObject, ObservableObject{
    @Published var bg1: Color
    @Published var bg2: Color
    @Published var fg: Color
    @Published var text: String
    @Published var primaryState = true
    private var secondaryBg1: Color
    private var secondaryBg2: Color
    private var secondaryFg: Color
    private var secondaryText: String
    
    init(bg1: Color, bg2: Color, fg: Color, text: String, secondaryBg1: Color, secondaryBg2: Color, secondaryFg: Color, secondaryText: String) {
        self.bg1 = bg1
        self.bg2 = bg2
        self.fg = fg
        self.text = text
        self.secondaryBg1 = secondaryBg1
        self.secondaryBg2 = secondaryBg2
        self.secondaryFg = secondaryFg
        self.secondaryText = secondaryText
    }
    
    func toggleBg1(){
        let temp = bg1
        bg1 = secondaryBg1
        secondaryBg1 = temp
    }
    func toggleBg2(){
        let temp = bg2
        bg2 = secondaryBg2
        secondaryBg2 = temp
    }
    func toggleFg(){
        let temp = fg
        fg = secondaryFg
        secondaryFg = temp
    }
    func toggleText(){
        let temp = text
        text = secondaryText
        secondaryText = temp
    }
    func toggleAllProperties(){
        toggleBg1()
        toggleBg2()
        toggleFg()
        toggleText()
        primaryState.toggle()
    }
}

struct UniversalStaticButtonView: View {
    let display: AnyView
    let primaryAction: () -> Void
    let secondaryAction: (String) -> Void
    let text: String
    @State private var primaryColor: Color
    @State private var secondaryColor: Color
    init(display: AnyView, primaryAction: @escaping () -> Void, secondaryAction: @escaping (String) -> Void, text: String, primaryColor: Color, secondaryColor: Color) {
        self.display = display
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.text = text
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
    
    var body: some View {
        display
            .shadow(radius: 5, x: -1, y: 2.5) // TODO: i may be dumb
            .foregroundStyle(LinearGradient(colors: [primaryColor, secondaryColor], startPoint: .topTrailing, endPoint: .bottomLeading))
            .onTapGesture {
                primaryAction()
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
            .onLongPressGesture(minimumDuration: 1) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                secondaryAction(text)
            } onPressingChanged: { value in
                let temp = primaryColor
                self.primaryColor = secondaryColor
                self.secondaryColor = temp
            }
    }
}

struct UniversalNavigationLinkView: View {
    let display: AnyView
    let destination: AnyView
    let secondaryAction: (String) -> Void
    let text: String
    let primaryColor: Color
    let secondaryColor: Color
    @Binding var activationBinding: Bool
    
    private func activateButton(){
        activationBinding.toggle()
    }
    var body: some View {
        UniversalStaticButtonView(display: display, primaryAction: activateButton, secondaryAction: secondaryAction, text: text, primaryColor: primaryColor, secondaryColor: secondaryColor)
        .navigationDestination(isPresented: $activationBinding) {
            destination
        }
    }
}

struct UniversalNavigationBar: View {
    let microphone: Microphone
    let homeAction: () -> Void
    let navigationAction: () -> Void
    let textAction: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor(hexString: "#3C3D59")))
                .frame(width: 354, height: 64)
                .cornerRadius(32)
                .shadow(radius: 5, x: -1, y: 2.5)
            HStack{
                UniversalStaticButtonView(display: AnyView(Imagecon(name: "home")), primaryAction: homeAction, secondaryAction: VoiceSynthesis.shared.textToSpeech, text: "home", primaryColor: Color(UIColor(hexString: "#e4b1d8")), secondaryColor: Color(UIColor(hexString: "#a8e1dd")))
                    .offset(x: -24)
                UniversalStaticButtonView(display: AnyView(EpicPolygon()), primaryAction: navigationAction, secondaryAction: VoiceSynthesis.shared.textToSpeech, text: "navigation", primaryColor: Color(UIColor(hexString: "#e4b1d8")), secondaryColor: Color(UIColor(hexString: "#a8e1dd")))
                UniversalStaticButtonView(display: AnyView(Imagecon(name: "text")), primaryAction: textAction, secondaryAction: VoiceSynthesis.shared.textToSpeech, text: "text detection", primaryColor: Color(UIColor(hexString: "#e4b1d8")), secondaryColor: Color(UIColor(hexString: "#a8e1dd")))
                    .offset(x: 24)
            }
        }
    }
}
