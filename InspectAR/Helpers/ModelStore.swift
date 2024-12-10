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
    
    static func saveModel(name: String, obj: Data? = nil, png: Data? = nil, json: Data? = nil) throws {
        let modelDirectory = baseDirectory.appendingPathComponent(name, isDirectory: true)
        
        try fileManager.createDirectory(at: modelDirectory, withIntermediateDirectories: true, attributes: nil)
        
        let objURL = modelDirectory.appendingPathComponent("model.obj")
        let pngURL = modelDirectory.appendingPathComponent("image.png")
        let jsonURL = modelDirectory.appendingPathComponent("map.json")
        
        // Write non-nil values
        try obj?.write(to: objURL)
        try png?.write(to: pngURL)
        try json?.write(to: jsonURL)
    }
    
    static func loadObj(name: String) -> SCNNode? {
        let modelDirectory = baseDirectory.appendingPathComponent(name, isDirectory: true)
        let objURL = modelDirectory.appendingPathComponent("model.obj")
        
        let scene = try? SCNScene(url: objURL, options: nil)
        let rootNode = scene?.rootNode.childNodes.first
        
        return rootNode
    }
    
    static func loadPng(name: String) -> UIImage? {
        let modelDirectory = baseDirectory.appendingPathComponent(name, isDirectory: true)
        let pngURL = modelDirectory.appendingPathComponent("image.png")
        
        // if fileManager.fileExists(atPath: pngURL.path) {}
        return UIImage(contentsOfFile: pngURL.path)
    }
    
    static func loadJson(name: String) -> [String: Any]? {
        let modelDirectory = baseDirectory.appendingPathComponent(name, isDirectory: true)
        let jsonURL = modelDirectory.appendingPathComponent("map.json")
        
        guard let jsonString = try? String(contentsOf: jsonURL, encoding: .utf8),
              let jsonData = jsonString.data(using: .utf8) else { return nil }
        
        let jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        
        return jsonDict
    }
}
