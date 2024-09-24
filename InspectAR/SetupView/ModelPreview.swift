//
//  ModelPreview.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SceneKit

func createScene() -> SCNScene {
    let scene = SCNScene()
    scene.background.contents = UIColor.gray.withAlphaComponent(0.2)
    
    // Create a sample mesh (cube) for demonstration
    // In a real app, you'd load the actual .obj file here
    let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1)
    let boxNode = SCNNode(geometry: box)
    scene.rootNode.addChildNode(boxNode)
    
    // Add rotation animation
    let rotation = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 10)
    let repeatRotation = SCNAction.repeatForever(rotation)
    boxNode.runAction(repeatRotation)
    
    // Add a camera to the scene
    let camera = SCNCamera()
    let cameraNode = SCNNode()
    cameraNode.camera = camera
    // Position the camera
    let d: Float = 1.25
    cameraNode.position = SCNVector3(d, d, d)
    cameraNode.look(at: SCNVector3(0, 0, 0))
    scene.rootNode.addChildNode(cameraNode)
    
    return scene
}
