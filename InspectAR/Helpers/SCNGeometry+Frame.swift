//
//  SCNNode+Frame.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SceneKit

extension SCNGeometry {
    static func frame(width: CGFloat, length: CGFloat) -> SCNGeometry {
        let frameThickness = min(width, length) * 0.01
        
        let outerRect = CGRect(x: -width/2, y: -length/2, width: width, height: length)
        let innerRect = outerRect.insetBy(dx: frameThickness, dy: frameThickness)
        
        let path = UIBezierPath(rect: outerRect)
        let holePath = UIBezierPath(rect: innerRect)
        
        path.append(holePath.reversing())
        
        let shape = SCNShape(path: path, extrusionDepth: 0.001)

        return shape
    }
}
