//
//  ARContainer+Gestures.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import ARKit
import SwiftUI

extension ARContainer {
    // MARK: - Gestures
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
        guard let sceneView,
              let object = sceneView.scene.rootNode.childNode(withName: "placed-object", recursively: false) else { return }
        
        if state == .placingObject || state == .objectPlaced {
            let rotation = Float(gesture.rotation)
            object.eulerAngles.y -= rotation
            gesture.rotation = 0
        }
    }
    
    @objc internal func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let sceneView,
              let object = sceneView.scene.rootNode.childNode(withName: "placed-object", recursively: false) else { return }
        
        if state == .objectPlaced {
            // Translating pan
            guard let nearestPlaneXYZ = raycastNearestPlaneSIMD(from: gesture.location(in: sceneView), sceneView: sceneView) else {
                return
            }
            
            switch gesture.state {
            case .began:
                panOffset = nearestPlaneXYZ - object.simdWorldPosition
            case .changed:
                object.simdWorldPosition = nearestPlaneXYZ - panOffset
            default:
                break
            }
  
            // Dynamic positioning pan
            /*
            switch gesture.state {
            case .began:
                guard let nearestPlaneXYZ = raycastNearestPlaneSIMD(from: gesture.location(in: sceneView), sceneView: sceneView) else { return }
                
                // Calculate initial position and offset
                initialPanPosition = nearestPlaneXYZ
                panOffset = nearestPlaneXYZ - object.simdWorldPosition
                
            case .changed:
                guard let initialPanPosition = initialPanPosition,
                      let nearestPlaneXYZ = raycastNearestPlaneSIMD(from: gesture.location(in: sceneView), sceneView: sceneView) else { return }
                
                // Calculate and update object position
                let currentPosition = nearestPlaneXYZ
                let translation = currentPosition - initialPanPosition
                
                let newPosition = initialPanPosition - panOffset + translation
                object.simdWorldPosition = newPosition
                
            case .ended:
                initialPanPosition = nil
                
            default:
                break
            }
            */
        }
    }
    
//    func gestureRecognizer(_ first: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith second: UIGestureRecognizer) -> Bool {
//        let includesTap = first is UITapGestureRecognizer || second is UITapGestureRecognizer
//        return !includesTap
//    }
    
    // MARK: - Raycast
    internal func raycastNearestPlane(from location: CGPoint, sceneView: ARSCNView) -> ARRaycastResult? {
        guard let query = sceneView.raycastQuery(from: location, allowing: .existingPlaneGeometry, alignment: .any) else { // Alignment is any, so type of planes managed by tracking config
            return nil
        }
        return sceneView.session.raycast(query).first
    }
    
    internal func raycastNearestPlaneSIMD(from location: CGPoint, sceneView: ARSCNView) -> SIMD3<Float>? {
        guard let nearestPlane = raycastNearestPlane(from: location, sceneView: sceneView) else { return nil }
        return nearestPlane.worldTransform.columns.3.xyz
    }
}
