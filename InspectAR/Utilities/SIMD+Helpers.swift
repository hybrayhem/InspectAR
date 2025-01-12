//
//  SIMD+Helpers.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import Foundation

extension SIMD4 where Scalar == Float {
    var xyz: SIMD3<Float> {
        get {
            return SIMD3<Float>(x, y, z)
        }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
}
