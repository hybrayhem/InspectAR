//
//  SCNNode+Normalized.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SceneKit
import Foundation

enum SizeUnit: Int {
    case m // 1.0
    case cm // 0.1
    case mm  // 0.01
    
    // Convert to meters
    func scaleFactor() -> Float {
        return 1 / pow(10, Float(self.rawValue))
    }
}

extension SCNNode {
    /// Scale to meters and set pivot to ground
    func normalized(unit: SizeUnit = .mm) -> Self {
        // Scale
        let s = unit.scaleFactor()
        self.scale = SCNVector3(s, s, s)
        
        // Pivot
        let (min, max) = self.boundingBox
        let center = SCNVector3(
            (min.x + max.x) / 2,
            (min.y + max.y) / 2,
            (min.z + max.z) / 2
        )
        self.pivot = SCNMatrix4MakeTranslation(center.x, min.y, center.z)
        
        // Debug Prints
        print(boundingBox)
        print(boundingSphere)
        
        return self
    }
}
