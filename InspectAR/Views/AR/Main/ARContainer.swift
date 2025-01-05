//
//  ARContainer.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI
import ARKit
//import SceneKit
import RealityKit

struct ARContainerRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> ARContainer {
        return ARContainer()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

class ARContainer: ARView {
    
    convenience init() {
        self.init(frame: UIScreen.main.bounds)
        
        let configuration = ARWorldTrackingConfiguration()
        session.run(configuration)
        
        let centerAnchor = AnchorEntity(world: .zero)
        let horizontalPlanes = AnchorEntity(plane: .horizontal)
        let verticalPlanes = AnchorEntity(plane: .vertical)
        let allPlanes = AnchorEntity(plane: .any, minimumBounds: .init(x: 30, y: 30))
        scene.addAnchor(centerAnchor)
        
        let entity = ModelEntity(/*mesh: SCNNode().geometry*/)
        centerAnchor.addChild(entity)
    }
}
