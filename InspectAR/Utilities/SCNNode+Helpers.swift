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
        print(scale)
        print(boundingBox)
        print(boundingSphere)
        
        return self
    }
    
    var worldBoundingBox: (min: SCNVector3, max: SCNVector3) {
        // Get local bounding box
        let boundingBox = self.boundingBox
        
        // Define the corners of the local bounding box
        let localCorners = [
            SCNVector3(boundingBox.min.x, boundingBox.min.y, boundingBox.min.z),
            SCNVector3(boundingBox.min.x, boundingBox.min.y, boundingBox.max.z),
            SCNVector3(boundingBox.min.x, boundingBox.max.y, boundingBox.min.z),
            SCNVector3(boundingBox.min.x, boundingBox.max.y, boundingBox.max.z),
            SCNVector3(boundingBox.max.x, boundingBox.min.y, boundingBox.min.z),
            SCNVector3(boundingBox.max.x, boundingBox.min.y, boundingBox.max.z),
            SCNVector3(boundingBox.max.x, boundingBox.max.y, boundingBox.min.z),
            SCNVector3(boundingBox.max.x, boundingBox.max.y, boundingBox.max.z)
        ]
        
        // Convert all corners to world coordinates
        let worldCorners = localCorners.map { corner in
            self.convertPosition(corner, to: nil)  // nil means convert to world space
        }
        
        // Find the minimum and maximum coordinates among all world corners
        let worldMin = SCNVector3(
            worldCorners.map { $0.x }.min() ?? 0,
            worldCorners.map { $0.y }.min() ?? 0,
            worldCorners.map { $0.z }.min() ?? 0
        )
        
        let worldMax = SCNVector3(
            worldCorners.map { $0.x }.max() ?? 0,
            worldCorners.map { $0.y }.max() ?? 0,
            worldCorners.map { $0.z }.max() ?? 0
        )
        
        return (worldMin, worldMax)
    }
}
