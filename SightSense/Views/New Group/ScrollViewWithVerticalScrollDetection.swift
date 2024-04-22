//
//  ScrollViewWithVerticalScrollDetection.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import SwiftUI
import PolyKit
import Combine

enum abstraction: String{
    case summarized = "summarized"
    case basic = "basic"
    case enhanced = "enhanced"
    
    var index: Int {
        switch self {
        case .summarized:
            return 1
        case .basic:
            return 2
        case .enhanced:
            return 3
        }
    }
    
    var name: String {
        switch self {
        case .summarized:
            return "summarized"
        case .basic:
            return "basic"
        case .enhanced:
            return "enhanced"
        }
    }

}

struct ScrollViewWithVerticalScrollDetection: View {
    @Binding var scrollLocation: abstraction
    @State private var scrollValue: Double = 0
    @State private var opacity: Double = 0
    @State private var location: Int = 0
    @State private var isProgrammaticallyScrolled = false
        
    @StateObject private var isScrollingStates: DebouncerState<Bool>
        
    init(scrollLocation: Binding<abstraction>) {
        self._scrollLocation = scrollLocation
        self._isScrollingStates = StateObject(wrappedValue: DebouncerState(original: false, delay: 0.75))
    }
        
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical) {
                    LazyVStack {
                        internalViewOfScrollDetection(indexs: $scrollLocation, index: .summarized, geometry: geometry, hue: 1.0, text: "summarized")
                            .opacity(opacity)
                            .id(1)
                        internalViewOfScrollDetection(indexs: $scrollLocation, index: .basic, geometry: geometry, hue: 4.0, text: "default")
                            .opacity(opacity)
                            .id(2)
                        internalViewOfScrollDetection(indexs: $scrollLocation, index: .enhanced, geometry: geometry, hue: 7.0, text: "detailed")
                            .opacity(opacity)
                            .id(3)
                    }
                    .background(GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).origin)
                    })
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollValue = round(Double(value.y)/10)*10
                        location = Int(abs(Float(value.y)/Float(geometry.size.height)).rounded())
                        isScrollingStates.original = false
                    }
                }
                .scrollIndicators(.hidden)
                .coordinateSpace(name: "scroll")
                .conditionalScrollTargetBehavior()
                    
                .onAppear {
                    isProgrammaticallyScrolled = true
                    scrollProxy.scrollTo(userDefaultLocation())
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isProgrammaticallyScrolled = false
                    }

                }
                .onChange(of: scrollValue) { newValue in
                    isScrollingStates.original = true
                    isScrollingStates.debounced = true
                }
                .onChange(of: isScrollingStates.debounced) { newValue in
                    if newValue == false {
                        //print("turned off thing")
                        turnOffView()
                    }
                }
                .onChange(of: isScrollingStates.original) { newValue in
                    if newValue == true && !isProgrammaticallyScrolled{
                        withAnimation {
                            opacity = 1
                        }
                    }
                }
                .onDisappear {
                    turnOffView()
                }
            }
        }
        .background(Color.clear)
        .allowsHitTesting(true)
    }
    
    func turnOffView(){
        switch location{
        case 1: scrollLocation = .basic
        case 2: scrollLocation = .enhanced
        default: scrollLocation = .summarized
        }
        
        withAnimation {
            opacity = 0
        }
        
        UserDefaultsManager.shared.set(scrollLocation.name, forKey: "navigationDescriptionAbstraction")
        //print(scrollLocation.name)
    }
    
    func userDefaultLocation() -> Int{
        let userDefaultMode = UserDefaultsManager.shared.string(forKey: "navigationDescriptionAbstraction", defaultValue: "basic")
        return abstraction(rawValue: userDefaultMode)?.index ?? 1
    }
    
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
    }
}

struct internalViewOfScrollDetection: View{
    @Binding var indexs: abstraction
    private var index: abstraction
    private var geometry: GeometryProxy
    private var hue: Double
    private var text: String
    
    init(indexs: Binding<abstraction>, index: abstraction, geometry: GeometryProxy, hue: Double, text: String){
        self._indexs = indexs
        self.index = index
        self.geometry = geometry
        self.hue = hue
        self.text = text
    }
    var body: some View{
        ZStack{
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(hue: hue / 10, saturation: 1, brightness: 1).gradient)
                .frame(width: 300, height: geometry.size.height)
            Text(text)
        }
    }
}

class DebouncerState<T>: ObservableObject {
    @Published var original: T
    @Published var debounced: T

    init (original: T, delay: Double = 0.5) {
        self.original = original
        self.debounced = original
        $original
            .debounce(for: .seconds(delay), scheduler: RunLoop.main)
            .assign(to: &$debounced)
    }
}
