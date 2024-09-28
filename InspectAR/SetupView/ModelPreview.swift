//
//  ModelPreview.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI
import SceneKit

class SceneState: ObservableObject {
    @Published var model: SCNNode
    @Published var isAnimating: Bool
    @Published var shouldResetCameraPose: Bool
    
    init() {
        model = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1))
        isAnimating = true
        shouldResetCameraPose = false
    }
}

struct ModelPreview: UIViewRepresentable {
    @ObservedObject var sceneState: SceneState
    
    // MARK: - Overrides
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = SCNScene()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.scene?.background.contents = UIColor.gray.withAlphaComponent(0.2)
        
        overrideGestureRecognizers(to: scnView, context: context)
        
        setupModel(scnView)
        setupCamera(scnView)
        setupAnimation(scnView)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        updateModel(uiView)
        updateCamera(uiView)
        updateAnimation(uiView)
    }
    
    // MARK: - Setup
    private func setupModel(_ scnView: SCNView) {
        let model = sceneState.model
        
        model.name = "model"
        scnView.scene?.rootNode.addChildNode(model)
    }
    
    private func setupCamera(_ scnView: SCNView) {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        setDefaultCameraPose(cameraNode)
        
        cameraNode.name = "camera"
        scnView.scene?.rootNode.addChildNode(cameraNode)
    }
    
    private func setupAnimation(_ scnView: SCNView) {
        if let model = scnView.scene?.rootNode.childNode(withName: "model", recursively: false) {
            let rotateAction = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 10)
            let repeatAction = SCNAction.repeatForever(rotateAction)
            
            model.runAction(repeatAction, forKey: "rotate")
        }
    }
    
    // MARK: - Update
    private func updateModel(_ scnView: SCNView) {
        if let currentModel = scnView.scene?.rootNode.childNode(withName: "model", recursively: false) {
            // scnView.scene?.rootNode.replaceChildNode(currentModel, with: sceneState.model)
            
            currentModel.geometry = sceneState.model.geometry
            // currentModel.position = sceneState.model.position
            // currentModel.orientation = sceneState.model.orientation
        }
    }
    
    private func updateCamera(_ scnView: SCNView) {
        if sceneState.shouldResetCameraPose,
           let currentCameraNode = scnView.scene?.rootNode.childNode(withName: "camera", recursively: false) {
            print("Update Camera")
            setDefaultCameraPose(currentCameraNode)
            scnView.pointOfView = currentCameraNode
            
            Task {
                sceneState.shouldResetCameraPose = false
            }
        }
    }
    
    private func updateAnimation(_ scnView: SCNView) {
        if let currentModel = scnView.scene?.rootNode.childNode(withName: "model", recursively: false) {
            // currentModel.animationPlayer(forKey: "rotate")?.paused = !sceneState.isAnimating
            currentModel.isPaused = !sceneState.isAnimating
        }
    }
    
    // MARK: - Helper
    private func setDefaultCameraPose(_ cameraNode: SCNNode) {
        let d: Float = 1.25
        cameraNode.position = SCNVector3(d, d, d)
        cameraNode.look(at: SCNVector3(0, 0, 0))
    }
    
}

extension ModelPreview {
    private func overrideGestureRecognizers(to scnView: SCNView, context: Context) {
        for recognizer in scnView.gestureRecognizers ?? [] {
            recognizer.addTarget(context.coordinator, action: #selector(Coordinator.handleAnyGesture))
        }
    }
    
    // MARK: - Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, SCNSceneRendererDelegate {
        var parent: ModelPreview
        
        init(_ parent: ModelPreview) {
            self.parent = parent
        }
        
        @objc func handleAnyGesture(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .began || gesture.state == .changed {
                parent.sceneState.isAnimating = false
            }
        }
    }
}

// MARK: - Preview
private struct PreviewContainer: View {
    @StateObject private var sceneState = SceneState()
    
    var body: some View {
        VStack {
            ModelPreview(sceneState: sceneState)
                .frame(height: 300)
            
            HStack {
                Button("Toggle Animation") {
                    sceneState.isAnimating.toggle()
                }
                Button("Reset Camera") {
                    sceneState.shouldResetCameraPose = true
                }
                Button("Change Model") {
                    let pyramid = SCNPyramid(width: 1, height: 1, length: 1)
                    sceneState.model = SCNNode(geometry: pyramid)
                }
            }
        }
    }
}

#Preview {
    PreviewContainer()
}
