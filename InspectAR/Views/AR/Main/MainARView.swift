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
//    let overlayType: enum
    
    var body: some View {
        ARContainerRepresentable()
            .ignoresSafeArea(.all)
    }
}

//#Preview {
//    MainARView(scnNode: SCNNode())
//}

struct MainARViewPreview: View {
    let model = ModelStore().load(name: "chassis.step")
    let box = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
    
    var body: some View {
        MainARView(scnNode: model?.scnNode ?? box)
    }
}
