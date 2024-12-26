//
//  GeometryBridge.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SceneKit
import Foundation

struct GeometryBridge {
    func fromObj(_ objs: String) -> RawGeometry {
        var rawg = RawGeometry()
        
        let lines = objs.components(separatedBy: .newlines)
        
        for line in lines {
            let components = line.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            guard !components.isEmpty else { continue }
            
            switch components[0] {
            case "g":
                // "g name"
                if components.count == 2 {
                    let name = components[1]
                    rawg.groups.append(RawGeometry.Group(name: name))
                }
            case "v":
                // "v x y z"
                if components.count == 4,
                   let x = Float(components[1]),
                   let y = Float(components[2]),
                   let z = Float(components[3]),
                   let last = rawg.lastGroupIndex {
                    rawg.groups[last].vertices.append(SCNVector3(x, y, z))
                }
            case "vt":
                // "vt u v"
                if components.count == 3,
                   let u = Float(components[1]),
                   let v = Float(components[2]),
                   let last = rawg.lastGroupIndex {
                    rawg.groups[last].textureCoordinates.append(CGPoint(x: CGFloat(u), y: CGFloat(v)))
                }
            case "f":
                if components.count == 4,
                   let last = rawg.lastGroupIndex,
                   let face = parseObjFace(components: components) {
                    rawg.groups[last].faces.append(face)
                }
            default:
                break
            }
        }
        
        // for group in rawg.groups {
        //     print("g \(group.name)\n \(group.vertices)\n \(group.textureCoordinates)\n \(group.faces)\n\n")
        // }
        
        return rawg
    }
    
    private func parseObjFace(components: [String]) -> RawGeometry.Face? {
        // Possible formats:
        //      f v v v                     , 1x3 component
        //      f v/vt v/vt v/vt            , 2x3 component
        //      f v//vn v//vn v//vn         , 3x3 component
        //      f v/vt/vn v/vt/vn v/vt/vn   , 3x3 component
        
        var face = RawGeometry.Face()
        
        let indices1 = components[1].components(separatedBy: "/")
        let indices2 = components[2].components(separatedBy: "/")
        let indices3 = components[3].components(separatedBy: "/")
        
        // Same amount of indices for each vertex attribute
        guard indices1.count > 0,
              indices1.count == indices2.count,
              indices2.count == indices3.count else {
            return nil
        }
        
        // Store indices
        if indices1.count > 0,
           let v1 = UInt32(indices1[0]),
           let v2 = UInt32(indices2[0]),
           let v3 = UInt32(indices3[0]) {
            face.vS.append(contentsOf: [v1, v2, v3])
        }
        
        if indices1.count > 1,
           let vt1 = UInt32(indices1[1]),
           let vt2 = UInt32(indices2[1]),
           let vt3 = UInt32(indices3[1]) {
            face.vtS.append(contentsOf: [vt1, vt2, vt3])
        }
        
        if indices1.count > 2,
           let vn1 = UInt32(indices1[2]),
           let vn2 = UInt32(indices2[2]),
           let vn3 = UInt32(indices3[2]) {
            face.vnS.append(contentsOf: [vn1, vn2, vn3])
        }

        return face
    }
    
    func toSceneGeometry(rawg: RawGeometry) -> SCNGeometry {
        return .init()
    }
}
