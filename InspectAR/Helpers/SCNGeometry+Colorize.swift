//
//  SCNGeometry+Colorize.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SceneKit
import Foundation

extension SCNGeometry {
    func clearColors() -> SCNGeometry {
        let sourcesWithoutColor = self.sources.filter { $0.semantic != .color }
        return SCNGeometry(sources: sourcesWithoutColor, elements: self.elements)
    }
    
    func colorizeElementsRandom(vertexCounts: [Int]) -> SCNGeometry? {
        var colors: [SCNVector3] = []
        
        for count in vertexCounts {            
            let r = Float.random(in: 0...1)
            let g = Float.random(in: 0...1)
            let b = Float.random(in: 0...1)
            
            colors.append(contentsOf: Array(repeating: SCNVector3(r, g, b), count: count))
        }
        
        let colorSource = SCNGeometrySource(
            data: NSData(bytes: colors, length: MemoryLayout<SCNVector3>.size * colors.count) as Data,
            semantic: .color,
            vectorCount: colors.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SCNVector3>.size
        )
        
        let newGeometry = SCNGeometry(sources: self.sources + [colorSource], elements: self.elements)
        
        return newGeometry
    }
    
    private func colorToVec(color: UIColor) -> SCNVector3 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: nil)
        return SCNVector3(Float(r), Float(g), Float(b))
    }
    
    func colorizeElementsAt(found: [Int], missing: [Int], nonvisible: [Int], vertexCounts: [Int]) -> SCNGeometry? {
        var colors: [SCNVector3] = []
        
        for (i, count) in vertexCounts.enumerated() {
            var color = colorToVec(color: .black)
            
            if found.contains(i) {
                color = colorToVec(color: .green)
            } else if missing.contains(i) {
                color = colorToVec(color: .red)
            } else if nonvisible.contains(i) {
                color = colorToVec(color: .gray)
            }
            
            colors.append(contentsOf: Array(repeating: color, count: count))
        }
        
        let colorSource = SCNGeometrySource(
            data: NSData(bytes: colors, length: MemoryLayout<SCNVector3>.size * colors.count) as Data,
            semantic: .color,
            vectorCount: colors.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SCNVector3>.size
        )
        
        let newGeometry = SCNGeometry(sources: self.sources + [colorSource], elements: self.elements)
        
        return newGeometry
    }
}
