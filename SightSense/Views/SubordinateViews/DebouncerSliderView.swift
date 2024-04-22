//
//  DebouncerSliderView.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import SwiftUI

struct DebouncedSteppedSlider: View{
    @Binding var value: Double
    @State var originalValue: Double
    @State var isEditingSpeedSlider: Bool = false
    @State var name: String
    let min: Double = 1.0
    let max: Double = 10.0
    
    let step: Double = 1.0
    init(value: Binding<Double>, name: String = "") {
        self._value = value
        self._originalValue = State(initialValue: value.wrappedValue)
        self.name = name
        
    }
    
    var body: some View{
        Slider(
            value: $originalValue,
            in: min...max,
            step: step,
            onEditingChanged: { editing in
                isEditingSpeedSlider = editing
            },
            minimumValueLabel: Text("\(min)"),
            maximumValueLabel: Text("\(max)")
        ) {
            Text("Slider Label") // Label for the Slider
        }

        .onChange(of: isEditingSpeedSlider){ newValue in
            if (!newValue){
                value = originalValue
            }
        }
    }
}
