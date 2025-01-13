//
//  Array+ClosestValue.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import Foundation

extension Array where Element == Float {
    func closestValueIndex(to value: Element) -> Int {
        var closestIndex = 0
        var smallestDifference = Float.greatestFiniteMagnitude
        
        for (index, element) in self.enumerated() {
            let difference = abs(element - value)
            if difference < smallestDifference {
                smallestDifference = difference
                closestIndex = index
            }
        }
        
        return closestIndex
    }
}
