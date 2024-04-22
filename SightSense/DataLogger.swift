//
//  DataLogger.swift
//  SightSense
//
//  Created by Owen Gregson on 4/6/24.
//

import Foundation

class DataLogger{
    
    func generateRandomString(length: Int) -> String {
        let lettersAndNumbers = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in lettersAndNumbers.randomElement()! })
    }

    func generateUID() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YMMdd"
        let dateStr = dateFormatter.string(from: Date())

        let firstPart = generateRandomString(length: 16)
        let secondPart = generateRandomString(length: 16 - dateStr.count - 1)
        let thirdPart = generateRandomString(length: 16)

        return "\(firstPart)-Y\(dateStr)X\(secondPart)-\(thirdPart)"
    }
}
