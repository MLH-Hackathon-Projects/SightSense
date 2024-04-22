//
//  TextPreview.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import SwiftUI

struct TextPreview: View{
    @Binding var text: String
    
    init(text: Binding<String>){
        self._text = text
    }
    var body: some View {
        GeometryReader { geometry in
            Text(text)
                .font(Font.custom("NotoSans-Regular", size: computeFontSize(for: geometry.size)))
                .opacity(0.75)
                .padding()
                .background(Color(UIColor(hexString: "#383948")).opacity(0.4))
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .multilineTextAlignment(.center)
                .frame(width: geometry.size.width - 30)
                .offset(y: -30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func computeFontSize(for size: CGSize) -> CGFloat {
        let baseWordCount: CGFloat = 40
        let baseFontSize: CGFloat = 22
        let wordCount = CGFloat(text.split(separator: " ").count)

        let wordCountFactor = max(0.5, 1 - (wordCount - baseWordCount) / 100)

        let spaceFactor = size.height / 500

        let fontSize = baseFontSize * wordCountFactor * spaceFactor

        let minFontSize: CGFloat = 12
        let maxFontSize: CGFloat = 25
        return min(max(fontSize, minFontSize), maxFontSize)
    }

}
