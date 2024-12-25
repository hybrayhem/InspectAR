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
