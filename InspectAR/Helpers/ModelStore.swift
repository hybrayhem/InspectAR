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
    
    static func saveBundle(name: String, obj: Data? = nil, png: Data? = nil, json: String? = nil) throws {
        let bundleDirectory = baseDirectory.appendingPathComponent(name, isDirectory: true)
        
        try fileManager.createDirectory(at: bundleDirectory, withIntermediateDirectories: true, attributes: nil)
        
        let objURL = bundleDirectory.appendingPathComponent("model.obj")
        let pngURL = bundleDirectory.appendingPathComponent("image.png")
        let jsonURL = bundleDirectory.appendingPathComponent("map.json")
        
        // Write non-nil values
        try obj?.write(to: objURL)
        try png?.write(to: pngURL)
        try json?.write(to: jsonURL, atomically: true, encoding: .utf8)
    }
    
//    func loadObject(name: String) throws -> (obj: URL, png: URL, txt: URL) {
//        let objectDirectory = baseDirectory.appendingPathComponent(name, isDirectory: true)
//        
//        let objURL = objectDirectory.appendingPathComponent("\(name).obj")
//        let pngURL = objectDirectory.appendingPathComponent("\(name).png")
//        let txtURL = objectDirectory.appendingPathComponent("\(name).txt")
//        
//        guard fileManager.fileExists(atPath: objURL.path),
//              fileManager.fileExists(atPath: pngURL.path),
//              fileManager.fileExists(atPath: txtURL.path) else {
//            throw NSError(domain: "FileArchiveError", code: 404, userInfo: [NSLocalizedDescriptionKey: "One or more files not found"])
//        }
//        
//        return (obj: objURL, png: pngURL, txt: txtURL)
//    }
//    
//    func loadObjectAsContent(name: String) throws -> (obj: SCNNode, png: UIImage, txt: String) {
//        let (objURL, pngURL, txtURL) = try loadObject(name: name)
//        
//        guard let scene = try? SCNScene(url: objURL, options: nil),
//              let rootNode = scene.rootNode.childNodes.first,
//              let image = UIImage(contentsOfFile: pngURL.path),
//              let text = try? String(contentsOf: txtURL, encoding: .utf8) else {
//            throw NSError(domain: "FileArchiveError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to load content"])
//        }
//        
//        return (obj: rootNode, png: image, txt: text)
//    }
}
