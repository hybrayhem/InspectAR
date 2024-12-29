//
//  RawGeometry.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SceneKit
import Foundation

struct RawGeometry {
    struct Face {
        var vS: [UInt32] = []
        var vtS: [UInt32] = []
        var vnS: [UInt32] = []
    }
    
    struct Group {
        var name: String
        var vertices: [SCNVector3] = []
        var textureCoordinates: [CGPoint] = []
        var normals: [SCNVector3] = []
        var faces: [Face] = []
    }
    
    var groups: [Group] = []
    
    var lastGroupIndex: Int? {
        guard groups.count > 0 else { return nil }
        return groups.count - 1
    }
}
