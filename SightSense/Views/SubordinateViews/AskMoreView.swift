//
//  AskGPTMore.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import SwiftUI

struct AskGPTMore: View {
        
        @State private var messageText: String = ""
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("What is on the left by my feet?")
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                Spacer()
                
                Text("Here is a more detailed description...")
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                Spacer()
                
                    .listStyle(PlainListStyle())
                
                HStack {
                    TextField("Message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: sendMessage) {
                        Text("Send")
                    }
                }
                .padding()
            }
            .padding(.bottom, 23)
            //.edgesIgnoringSafeArea(32 > 0 ? .bottom : [])
        }
    }
    
    private func sendMessage(){
        
    }
}

