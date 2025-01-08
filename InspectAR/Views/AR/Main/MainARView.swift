//
//  MainARView.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI
//import ARKit
import SceneKit
//import RealityKit

struct MainARView: View {
    let scnNode: SCNNode
    // let overlayType: enum
    let container: ARContainerRepresentable
    
    init(scnNode: SCNNode) {
        self.scnNode = scnNode
        self.container = ARContainerRepresentable(objectToPlace: scnNode)
    }
    
    var body: some View {
        container
            .ignoresSafeArea(.all)
    }
}

//#Preview {
//    MainARView(scnNode: SCNNode())
//}

struct MainARViewPreview: View {
    let model = ModelStore().load(name: "chassis.step")
    let box = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
    
    var node: SCNNode? {
        let node = model?.scnNode
        let s = 0.001
        node?.scale = SCNVector3(s, s, s)
        return node
    }
    
    var body: some View {
        MainARView(scnNode: node ?? box)
    }
}
