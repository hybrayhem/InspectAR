//
//  ModelStore.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SceneKit
import Foundation

fileprivate enum SubFileNames {
    static let obj = "model.obj"
    static let png = "image.png"
    static let json = "map.json"
}

struct Model {
    let name: String
    private let objURL: URL?
    private let pngURL: URL?
    private let jsonURL: URL?
    
    init(name: String, objURL: URL? = nil, pngURL: URL? = nil, jsonURL: URL? = nil) {
        self.name = name
        self.objURL = objURL
        self.pngURL = pngURL
        self.jsonURL = jsonURL
    }
    
    // obj
    private var _nodeCache: SCNNode? = nil
    var modelNode: SCNNode? {
        if _nodeCache == nil, let objURL = objURL {
            let scene = try? SCNScene(url: objURL)
            return scene?.rootNode.childNodes.first
        }
        return _nodeCache
    }
    
    // png
    private var _imageCache: UIImage? = nil
    var modelImage: UIImage? {
        if _imageCache == nil, let pngURL = pngURL {
            return UIImage(contentsOfFile: pngURL.path)
        }
        return _imageCache
    }
    
    // json
    private var _jsonCache: [String: Any]? = nil
    var faceTriMap: [String: Any]? {
        if _jsonCache == nil, let jsonURL = jsonURL {
            let jsonString = try? String(contentsOf: jsonURL, encoding: .utf8)
            guard let jsonData = jsonString?.data(using: .utf8) else { return nil }
            
            return try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        }
        return _jsonCache
    }
}

struct ModelStore {
    private let fileManager: FileManager
    private let baseDirectory: URL
    
    init(fileManager: FileManager = .default, baseDirectory: URL = .documentsDirectory) {
        self.fileManager = fileManager
        self.baseDirectory = baseDirectory
    }
    
    private func modelDirectory (for name: String) -> URL {
        return baseDirectory.appendingPathComponent(name, isDirectory: true)
    }
    
    func save(name: String, obj: Data? = nil, png: Data? = nil, json: Data? = nil) throws {
        let modelDirectory = modelDirectory(for: name)
        
        // Paths
        let objURL = modelDirectory.appendingPathComponent(SubFileNames.obj)
        let pngURL = modelDirectory.appendingPathComponent(SubFileNames.png)
        let jsonURL = modelDirectory.appendingPathComponent(SubFileNames.json)
        
        // Write non-nil values
        try obj?.write(to: objURL)
        try png?.write(to: pngURL)
        try json?.write(to: jsonURL)
    }
    
    func load(name: String) -> Model {
        let modelDirectory = modelDirectory(for: name)
        let objURL = modelDirectory.appendingPathComponent(SubFileNames.obj)
        let pngURL = modelDirectory.appendingPathComponent(SubFileNames.png)
        let jsonURL = modelDirectory.appendingPathComponent(SubFileNames.json)
        
        // No fileExists check, values are optional
        
        return Model(name: name, objURL: objURL, pngURL: pngURL, jsonURL: jsonURL)
    }
    
    func list() -> [String] {
        let contents = try? fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
        return contents?.compactMap { $0.lastPathComponent } ?? []
    }
}
