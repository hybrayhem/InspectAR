//
//  ARContainer+Gestures.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import ARKit
import SwiftUI

extension ARContainer: UIGestureRecognizerDelegate {
    // MARK: - Gestures
    @objc internal func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended,
              let sceneView,
              let objectToPlace else { return }
        
        stateLock.lock()
        if state == .placingObject {
            // Place the object
            let object = objectToPlace.clone()
            object.position = placeAt.position
            // object.opacity = 0.9
            object.name = "placed-object"
            sceneView.scene.rootNode.addChildNode(object)
            
            let groundCorrection = placeAt.position.y - object.worldBoundingBox.min.y
            object.position.y += groundCorrection
            
            // Update state
            state = .objectPlaced
        }
        stateLock.unlock()
    }
    
    @objc internal func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended,
              let sceneView,
              let objectToPlace,
              let object = sceneView.scene.rootNode.childNode(withName: "placed-object", recursively: false) else { return }
        
        if state == .objectPlaced {
            // Reset object transformation
            object.position = placeAt.position
            object.eulerAngles = objectToPlace.eulerAngles
            object.scale = objectToPlace.scale
        }
    }
    
    @objc internal func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let sceneView,
              let object = sceneView.scene.rootNode.childNode(withName: "placed-object", recursively: false) else { return }
        
        if state == .placingObject || state == .objectPlaced {
            let rotation = Float(gesture.rotation)
            object.eulerAngles.y -= rotation
        }
        gesture.rotation = 0
    }

    @objc internal func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let sceneView,
              let initialObjectScale,
              let object = sceneView.scene.rootNode.childNode(withName: "placed-object", recursively: false) else { return }
        
        let upscaleThreshold: Float = 1.25
        let downscaleThreshold: Float = 0.75
        
        if state == .objectPlaced {
            switch gesture.state {
            case .began:
                let realScale = object.scale / initialObjectScale
                let averageScale = Float(realScale.x + realScale.y + realScale.z) / 3
                currentScaleStepIndex = scaleSteps.closestValueIndex(to: averageScale)
            
            case .changed:
                let pinchScale = Float(gesture.scale)

                if pinchScale > upscaleThreshold {
                    if currentScaleStepIndex + 1 < scaleSteps.count {
                        currentScaleStepIndex += 1
                    }
                    gesture.scale = 1.0
                } else if pinchScale < downscaleThreshold {
                    if currentScaleStepIndex - 1 >= 0 {
                        currentScaleStepIndex -= 1
                    }
                    gesture.scale = 1.0
                }
                
                let newScale = scaleSteps[currentScaleStepIndex]
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.3
                object.scale = initialObjectScale * SCNVector3(newScale, newScale, newScale)
                SCNTransaction.commit()
                
            default:
                break
            }
        }
    }
    
    @objc internal func handleDoublePan(_ gesture: UIPanGestureRecognizer) {
        guard let sceneView,
              let object = sceneView.scene.rootNode.childNode(withName: "placed-object", recursively: false) else { return }
        
        if state == .placingObject || state == .objectPlaced {
            let translationY = gesture.translation(in: sceneView).y
            
            if abs(translationY) > 50 {
                guard let camera = sceneView.pointOfView else { return }
                let oldGroundY = object.worldBoundingBox.min.y
                
                // Draw a vector from camera to object
                let camToObj = object.worldPosition - camera.worldPosition // let camToObj = object.worldFront - camera.worldFront // TODO: Fix rotated object case
                let camToObjArr = [camToObj.x, camToObj.y, camToObj.z]
                let camFacingAxis = camToObjArr.enumerated().min { abs($0.element) < abs($1.element) }?.offset // min difference
                
                let rotationAngle: Float = translationY > 0 ? .pi/2 : -.pi/2
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.2
                if camFacingAxis == 0 {
                    object.eulerAngles.x += rotationAngle
                } else if camFacingAxis == 1 {
                    object.eulerAngles.y += rotationAngle
                } else if camFacingAxis == 2 {
                    object.eulerAngles.z += rotationAngle
                }

                let newGroundY = object.worldBoundingBox.min.y
                let groundCorrection = oldGroundY - newGroundY
                object.position.y += groundCorrection
                SCNTransaction.commit()
                
                // Reset gesture
                gesture.setTranslation(.zero, in: sceneView)
            }
        }
    }
    
    @objc internal func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let sceneView,
              let object = sceneView.scene.rootNode.childNode(withName: "placed-object", recursively: false) else { return }
        
        if state == .objectPlaced {
//            // 1. Translating pan
//            let translation = gesture.translation(in: sceneView)
//            object.position.x += Float(translation.x) / 1000
//            object.position.z -= Float(-translation.y) / 1000
//            gesture.setTranslation(.zero, in: sceneView)

            // 2. Positioning pan
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
  
//            // 3. Dynamic positioning pan
//            switch gesture.state {
//            case .began:
//                guard let nearestPlaneXYZ = raycastNearestPlaneSIMD(from: gesture.location(in: sceneView), sceneView: sceneView) else { return }
//                
//                // Calculate initial position and offset
//                initialPanPosition = nearestPlaneXYZ
//                panOffset = nearestPlaneXYZ - object.simdWorldPosition
//                
//            case .changed:
//                guard let initialPanPosition = initialPanPosition,
//                      let nearestPlaneXYZ = raycastNearestPlaneSIMD(from: gesture.location(in: sceneView), sceneView: sceneView) else { return }
//                
//                // Calculate and update object position
//                let currentPosition = nearestPlaneXYZ
//                let translation = currentPosition - initialPanPosition
//                
//                let newPosition = initialPanPosition - panOffset + translation
//                object.simdWorldPosition = newPosition
//                
//            case .ended:
//                initialPanPosition = nil
//                
//            default:
//                break
//            }
        }
    }
    
    // MARK: - Delegate
//    func gestureRecognizer(_ first: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith second: UIGestureRecognizer) -> Bool {
////        let includesTap = first is UITapGestureRecognizer || second is UITapGestureRecognizer
////        return !includesTap
//        return false
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
