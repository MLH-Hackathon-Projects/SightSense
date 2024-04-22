//
//  EditDefaultCode.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import Foundation
import CoreML
import UIKit
import SwiftUI

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension View {
    @ViewBuilder
    func conditionalScrollTargetBehavior() -> some View {
        if #available(iOS 17.0, *) {
            self.scrollTargetBehavior(.paging)
        } else {
            self
        }
    }
}

extension String {
    func levenshteinDistance(to string: String) -> Int {
        let empty = [Int](repeating:0, count: string.count)
        var last = [Int](0...string.count)

        for (i, selfChar) in self.enumerated() {
            var cur = [i + 1] + empty
            for (j, stringChar) in string.enumerated() {
                cur[j + 1] = selfChar == stringChar ? last[j] : Swift.min(last[j], last[j + 1], cur[j]) + 1
            }
            last = cur
        }
        return last.last!
    }
    
    func similarity(to string: String) -> Double {
        let maxLength = max(self.count, string.count)
        guard maxLength > 0 else { return 1.0 }
        let distance = self.levenshteinDistance(to: string)
        return 1.0 - (Double(distance) / Double(maxLength))
    }
}
