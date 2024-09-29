//
//  ModelStore.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SceneKit
import Foundation

struct ModelStore {
    private static let fileManager = FileManager.default
    private static var baseDirectory: URL = .documentsDirectory
    
    static func saveModel(name: String, obj: Data? = nil, png: Data? = nil, json: String? = nil) throws {
        let modelDirectory = baseDirectory.appendingPathComponent(name, isDirectory: true)
        
        try fileManager.createDirectory(at: modelDirectory, withIntermediateDirectories: true, attributes: nil)
        
        let objURL = modelDirectory.appendingPathComponent("model.obj")
        let pngURL = modelDirectory.appendingPathComponent("image.png")
        let jsonURL = modelDirectory.appendingPathComponent("map.json")
        
        // Write non-nil values
        try obj?.write(to: objURL)
        try png?.write(to: pngURL)
        try json?.write(to: jsonURL, atomically: true, encoding: .utf8)
    }
    
    static func loadObj(name: String) -> SCNNode? {
        let modelDirectory = baseDirectory.appendingPathComponent(name, isDirectory: true)
        let objURL = modelDirectory.appendingPathComponent("model.obj")
        
        let scene = try? SCNScene(url: objURL, options: nil)
        let rootNode = scene?.rootNode.childNodes.first
        
        return rootNode
    }
}
