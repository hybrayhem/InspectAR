//
//  ARContainer+Gestures.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI
import SceneKit

extension ARContainer {
    @objc internal func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let sceneView,
              let objectToPlace else { return }
        
        stateLock.lock()
        if state == .placingObject {
            // Place the object
            let object = objectToPlace.clone()
            object.position = placeAt.position
            // object.opacity = 0.9
            object.name = "placed-object"
            sceneView.scene.rootNode.addChildNode(object)
            
            // Update state
            state = .objectPlaced
        }
        stateLock.unlock()
    }
    
    @objc internal func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let object = sceneView?.scene.rootNode.childNode(withName: "placed-object", recursively: false) else { return }
        
        if state == .placingObject || state == .objectPlaced {
            let rotation = Float(gesture.rotation)
            object.eulerAngles.y -= rotation
            gesture.rotation = 0
        }
    }
    
    @objc internal func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let object = sceneView?.scene.rootNode.childNode(withName: "placed-object", recursively: false) else { return }
        
        if state == .objectPlaced {
            let translation = gesture.translation(in: sceneView)
            let x = Float(translation.x)
            let y = Float(-translation.y)
            
            object.position.x += x / 1000
            object.position.z -= y / 1000
            
            gesture.setTranslation(.zero, in: sceneView)
        }
    }
        
//    func gestureRecognizer(_ first: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith second: UIGestureRecognizer) -> Bool {
//        let includesTap = first is UITapGestureRecognizer || second is UITapGestureRecognizer
//        return !includesTap
//    }
}
