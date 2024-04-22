//
//  SwiftUIView.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import SwiftUI
import PolyKit

struct EpicPolygon: View{
    var body: some View {
        ZStack{
            Polygon(count: 7, cornerRadius: 10)
                .frame(width: 82, height: 80)
            Image("eye")
                .resizable()
                .frame(width: 50, height: 50)
        }
        .contentShape(Rectangle())
    }
}

struct resizablePolygon: View{
    let polygonWidth: CGFloat
    let polygonHeight: CGFloat
    let cornerRadius: CGFloat
    
    let logoWidth: CGFloat
    let logoHeight: CGFloat
    
    var body: some View{
        ZStack{
            Polygon(count: 7, cornerRadius: cornerRadius)
                .frame(width: polygonWidth, height: polygonHeight)
            Image("eye")
                .resizable()
                .frame(width: logoWidth, height: logoHeight)
        }
        .contentShape(Rectangle())

    }
}

struct Imagecon: View{
    let name: String
    var body: some View {
        Image(name)
            .resizable()
            .frame(width: 50, height: 50)
    }
}

struct ScalableImageIcon: View{
    let name: String
    let width: CGFloat
    let height: CGFloat
    var body: some View {
        Image(name)
            .resizable()
            .frame(width: width, height: height)
    }

}
