//
//  ARContainer+Gestures.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI

extension ARContainer {
    @objc internal func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let sceneView,
              let objectToPlace else { return }
        
        stateLock.lock()
        if state == .placingObject {
            let object = objectToPlace.clone()
            object.position = placeAt.position
            // object.opacity = 0.9
            
            sceneView.scene.rootNode.addChildNode(object)
            state = .objectPlaced
        }
        stateLock.unlock()
    }
}
