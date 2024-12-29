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
                // "g name name ..."
                if components.count > 1 {
                    let name = components[1...].joined(separator: " ")
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
            case "vn":
                // "vn x y z"
                if components.count == 4,
                   let x = Float(components[1]),
                   let y = Float(components[2]),
                   let z = Float(components[3]),
                   let last = rawg.lastGroupIndex {
                    rawg.groups[last].normals.append(SCNVector3(x, y, z))
                }
            // TODO:
            // case "vc":
                // "vc r g b"
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
        //     print("g \(group.name)\n \(group.vertices)\n \(group.textureCoordinates)\n \(group.normals)\n \(group.faces)\n\n")
        // }
        
        return rawg
    }
    
    private func parseObjFace(components: [String]) -> RawGeometry.Face? {
        // Possible formats:
        //      f v v v                     , 1x3 components
        //      f v/vt v/vt v/vt            , 2x3 components
        //      f v//vn v//vn v//vn         , 3x3 components
        //      f v/vt/vn v/vt/vn v/vt/vn   , 3x3 components
        
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
            face.vS.append(contentsOf: [v1 - 1, v2 - 1, v3 - 1]) // convert 1-based to 0-based
        }
        
        if indices1.count > 1,
           let vt1 = UInt32(indices1[1]),
           let vt2 = UInt32(indices2[1]),
           let vt3 = UInt32(indices3[1]) {
            face.vtS.append(contentsOf: [vt1 - 1, vt2 - 1, vt3 - 1]) // convert 1-based to 0-based
        }
        
         if indices1.count > 2,
            let vn1 = UInt32(indices1[2]),
            let vn2 = UInt32(indices2[2]),
            let vn3 = UInt32(indices3[2]) {
             face.vnS.append(contentsOf: [vn1 - 1, vn2 - 1, vn3 - 1]) // convert 1-based to 0-based
         }

        return face
    }
    
    func getGroupNames(from objs: String) -> [String] {
        var names: [String] = []
        
        let lines = objs.components(separatedBy: .newlines)
        for line in lines {
            if line.starts(with: "g ") {
                let name = String(line.dropFirst(2))
                names.append(name)
            }
        }
        return names
    }
    
    func getVertexCounts(from objs: String) -> [Int] {
        var counts: [Int] = []
        
        let lines = objs.components(separatedBy: .newlines)
        for line in lines {
            if line.starts(with: "g ") {
                counts.append(0)
            } else if line.starts(with: "v ") {
                guard counts.count > 0 else { continue }
                counts[counts.count - 1] += 1
            }
        }
        return counts
    }
    
    func toSceneGeometry(rawg: RawGeometry) -> SCNGeometry {
        // Vertices
        var allVertices: [SCNVector3] = []
        for group in rawg.groups {
            allVertices.append(contentsOf: group.vertices)
        }
        let positionSource = SCNGeometrySource(vertices: allVertices)
        
        // Texture Coordinates
        var allTextureCoordinates: [CGPoint] = []
        for group in rawg.groups {
            allTextureCoordinates.append(contentsOf: group.textureCoordinates)
        }
        let textureSource = SCNGeometrySource(textureCoordinates: allTextureCoordinates)
        
        // Normals
        var allNormals: [SCNVector3] = []
        for group in rawg.groups {
            allNormals.append(contentsOf: group.normals)
        }
        let normalsSource = SCNGeometrySource(normals: allNormals)
        
        // Vertex Colors
        // var allColors: [SCNVector3] = [] // TODO: Get all colors from obj
        // let colorSource = SCNGeometrySource(
        //     data: NSData(bytes: allColors, length: MemoryLayout<SCNVector3>.size * allColors.count) as Data,
        //     semantic: .color,
        //     vectorCount: allColors.count,
        //     usesFloatComponents: true,
        //     componentsPerVector: 3,
        //     bytesPerComponent: MemoryLayout<Float>.size,
        //     dataOffset: 0,
        //     dataStride: MemoryLayout<SCNVector3>.size
        // )
        
        // Elements for each group
        var elements: [SCNGeometryElement] = []
        for group in rawg.groups {
            let indices: [UInt32] = group.faces.flatMap { $0.vS }
            let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
            elements.append(element)
        }
        
        // Build Geometry
        let sources = [positionSource, textureSource, normalsSource/*, colorSource*/].filter { !$0.data.isEmpty }
        let scng = SCNGeometry(sources: sources, elements: elements)
        
        return scng
    }
}
