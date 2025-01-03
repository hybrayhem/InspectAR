//
//  ModelAlignView.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI
import SceneKit

struct ModelAlignView: View {
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
    ModelAlignView(scnNode: SCNNode())
}
