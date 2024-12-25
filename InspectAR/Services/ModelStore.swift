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

struct ModelStore {
    private let fileManager: FileManager
    private let baseDirectory: URL
    
    init(fileManager: FileManager = .default, baseDirectory: URL = .documentsDirectory) {
        self.fileManager = fileManager
        self.baseDirectory = baseDirectory
    }
    
    private func modelDirectory (for name: String) -> URL? {
        let dir = baseDirectory.appendingPathComponent(name, isDirectory: true)
        
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        
        return dir
    }
    
    func save(name: String, obj: Data? = nil, png: Data? = nil, json: Data? = nil) throws {
        guard let modelDirectory = modelDirectory(for: name) else { return }
        
        // Paths
        let objURL = modelDirectory.appendingPathComponent(SubFileNames.obj)
        let pngURL = modelDirectory.appendingPathComponent(SubFileNames.png)
        let jsonURL = modelDirectory.appendingPathComponent(SubFileNames.json)
        
        // Write non-nil values
        try obj?.write(to: objURL)
        try png?.write(to: pngURL)
        try json?.write(to: jsonURL)
    }
    
    func load(name: String) -> Model? {
        guard let modelDirectory = modelDirectory(for: name) else { return nil }
        
        let objURL = modelDirectory.appendingPathComponent(SubFileNames.obj)
        let pngURL = modelDirectory.appendingPathComponent(SubFileNames.png)
        let jsonURL = modelDirectory.appendingPathComponent(SubFileNames.json)
        
        // No fileExists check, values are optional
        
        return Model(name: name, objURL: objURL, pngURL: pngURL, jsonURL: jsonURL)
    }
    
    func delete(name: String) {
        guard let modelDirectory = modelDirectory(for: name) else { return }
        
        try? fileManager.removeItem(at: modelDirectory)
    }
    
    func list() -> [String] {
        let contents = try? fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
        return contents?.compactMap { $0.lastPathComponent } ?? []
    }
}
