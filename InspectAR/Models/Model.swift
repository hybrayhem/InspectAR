//
//  Model.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SceneKit
import Foundation

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
    lazy var scnNode: SCNNode? = {
        guard let objURL else { return nil }
        
        if let objString = try? String(contentsOf: objURL, encoding: .utf8) {
            let geometryBridge = GeometryBridge()
            let rawGeometry = geometryBridge.fromObj(objString)
            let scnGeometry = geometryBridge.toSceneGeometry(rawg: rawGeometry)
            return SCNNode(geometry: scnGeometry)
        }
        
        let scene = try? SCNScene(url: objURL)
        return scene?.rootNode.childNodes.first
    }() // lazy closures for caching
    
    // png
    lazy var modelImage: UIImage? = {
        guard let pngURL else { return nil }
        return UIImage(contentsOfFile: pngURL.path)
    }()
    
    // json
    lazy var faceTriMap: [String: Any]? = {
        guard let jsonURL else { return nil }
        
        let jsonString = try? String(contentsOf: jsonURL, encoding: .utf8)
        guard let jsonData = jsonString?.data(using: .utf8) else { return nil }
        
        return try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    }()
}
