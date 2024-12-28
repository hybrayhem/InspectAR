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
        var vnS: [UInt32] = []
        var vtS: [UInt32] = []
    }
    
    struct Group {
        var name: String
        var vertices: [SCNVector3] = []
        var textureCoordinates: [CGPoint] = []
        var faces: [Face] = []
    }
    
    var groups: [Group] = []
    
    var lastGroupIndex: Int? {
        guard groups.count > 0 else { return nil }
        return groups.count - 1
    }
}

extension RawGeometry {
    func calculateNormals(allVertices: [SCNVector3]) -> [SCNVector3] {
        var allNormals: [SCNVector3] = []
        
        for groupIndex in 0..<groups.count {
            let groupNormals = calculateGroupNormals(for: groups[groupIndex], allVertices: allVertices)
            allNormals.append(contentsOf: groupNormals)
        }
        
        return allNormals
    }
    
    /// Calculates vertex normals for a single group
    private func calculateGroupNormals(for group: Group, allVertices vertices: [SCNVector3]) -> [SCNVector3] {
//        let vertices = group.vertices
        var normalSums: [SCNVector3] = Array(repeating: SCNVector3Zero, count: vertices.count)
        var normalCounts: [Int] = Array(repeating: 0, count: vertices.count)
        
        // Calculate face normals and accumulate them for vertices
        for face in group.faces {
            guard face.vS.count >= 3 else { continue }
            
            // Calculate face normal using the first triangle of the face
            let v0 = vertices[Int(face.vS[0])]
            let v1 = vertices[Int(face.vS[1])]
            let v2 = vertices[Int(face.vS[2])]
            
            // Calculate vectors for two edges of the triangle
            let edge1 = SCNVector3(
                v1.x - v0.x,
                v1.y - v0.y,
                v1.z - v0.z
            )
            let edge2 = SCNVector3(
                v2.x - v0.x,
                v2.y - v0.y,
                v2.z - v0.z
            )
            
            // Calculate face normal using cross product
            let normal = SCNVector3(
                edge1.y * edge2.z - edge1.z * edge2.y,
                edge1.z * edge2.x - edge1.x * edge2.z,
                edge1.x * edge2.y - edge1.y * edge2.x
            )
            
            // Add this face normal to all vertices of the face
            for vertexIndex in face.vS {
                normalSums[Int(vertexIndex)] = SCNVector3(
                    normalSums[Int(vertexIndex)].x + normal.x,
                    normalSums[Int(vertexIndex)].y + normal.y,
                    normalSums[Int(vertexIndex)].z + normal.z
                )
                normalCounts[Int(vertexIndex)] += 1
            }
        }
        
        // Average and normalize the accumulated normals
        var finalNormals: [SCNVector3] = []
        for i in 0..<vertices.count {
            if normalCounts[i] > 0 {
                let avgNormal = SCNVector3(
                    normalSums[i].x / Float(normalCounts[i]),
                    normalSums[i].y / Float(normalCounts[i]),
                    normalSums[i].z / Float(normalCounts[i])
                )
                
                // Normalize the vector
                let length = sqrt(
                    avgNormal.x * avgNormal.x +
                    avgNormal.y * avgNormal.y +
                    avgNormal.z * avgNormal.z
                )
                
                if length > 0 {
                    finalNormals.append(SCNVector3(
                        avgNormal.x / length,
                        avgNormal.y / length,
                        avgNormal.z / length
                    ))
                } else {
                    finalNormals.append(SCNVector3(0, 1, 0)) // Default normal if calculation fails
                }
            } else {
                finalNormals.append(SCNVector3(0, 1, 0)) // Default normal for unused vertices
            }
        }
        
        return finalNormals
    }
}
