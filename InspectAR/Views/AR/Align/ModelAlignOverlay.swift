//
//  ModelAlignOverlay.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI
import ARKit
import SceneKit

struct ModelAlignOverlay: View {
    let scnNode: SCNNode
    
    var body: some View {
        VStack {
            Text("Align Model")
            // Add your model inspection UI here
        }
        .navigationTitle("Align Model")
    }
}

#Preview {
    ModelAlignOverlay(scnNode: SCNNode())
}
