//
//  SCNVector+Helpers.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SceneKit

extension SCNVector3 {
    func normalized() -> SCNVector3 {
        let length = sqrt(x * x + y * y + z * z)
        guard length > 0 else { return self }
        return SCNVector3(x / length, y / length, z / length)
    }

    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            left.x - right.x,
            left.y - right.y,
            left.z - right.z
        )
    }
    
    static func * (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            left.x * right.x,
            left.y * right.y,
            left.z * right.z
        )
    }
    
    static func / (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            left.x / right.x,
            left.y / right.y,
            left.z / right.z
        )
    }
}
