//
//  ARContainer+Gestures.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI

extension ARContainer {
    @objc internal func handleTap(_ gesture: UITapGestureRecognizer) {
        guard isPlacementValid,
              let sceneView,
              let objectToPlace else { return }
        
        let object = objectToPlace.clone()
        let s = 0.001 // Remove
        object.scale = .init(s, s, s) // Remove
        object.position = placeAt.position
        
        sceneView.scene.rootNode.addChildNode(object)
    }
}
