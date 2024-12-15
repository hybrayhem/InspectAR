//
//  ModelPreviewView.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI
import SceneKit

class SceneState: ObservableObject {
    @Published var name: String?
    @Published var model: SCNNode
    @Published var isAnimating: Bool
    @Published var shouldResetCameraPose: Bool
    @Published var shouldTakeSnapshot: Bool
    
    init(name: String? = nil, model: SCNNode) {
        self.name = name
        self.model = model
        isAnimating = true
        shouldResetCameraPose = false
        shouldTakeSnapshot = false
    }
    
    convenience init() {
        self.init(model: SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1)))
    }
}

struct ModelPreviewView: UIViewRepresentable {
    @ObservedObject var sceneState: SceneState
    let modelStore = ModelStore()
    
    // MARK: - Overrides
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = SCNScene()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.scene?.background.contents = UIColor.systemIndigo // gray.withAlphaComponent(0.2)
        
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
        updateSnapshot(uiView)
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
        // cameraNode.camera?.usesOrthographicProjection = true
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
            currentModel.geometry = sceneState.model.geometry
            currentModel.scale = sceneState.model.scale
            currentModel.pivot = sceneState.model.pivot
            
            // currentModel.orientation = sceneState.model.orientation
            currentModel.position = sceneState.model.position
        }
    }
    
    private func updateCamera(_ scnView: SCNView) {
        if sceneState.shouldResetCameraPose,
           let currentCameraNode = scnView.scene?.rootNode.childNode(withName: "camera", recursively: false) {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            print("Update Camera")
            setDefaultCameraPose(currentCameraNode)
            scnView.pointOfView = currentCameraNode
            
            SCNTransaction.commit()
            
            // Task {
            DispatchQueue.main.async {
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
    
    private func updateSnapshot(_ scnView: SCNView) {
        if sceneState.shouldTakeSnapshot {
            if let name = sceneState.name {
                try? modelStore.save(name: name, png: scnView.snapshot().pngData())
            }
            
            DispatchQueue.main.async {
                sceneState.shouldTakeSnapshot = false
            }
        }
    }
    
    // MARK: - Helper
    private func setDefaultCameraPose(_ cameraNode: SCNNode) {
        let d: Float = 2.5
        cameraNode.position = SCNVector3(d, d, d)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        
        // cameraNode.simdPosition = sceneState.model.simdWorldFront * -5
    }
    
}

extension ModelPreviewView {
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
        var parent: ModelPreviewView
        
        init(_ parent: ModelPreviewView) {
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
    let modelStore = ModelStore()
    
    var body: some View {
        VStack {
            ModelPreviewView(sceneState: sceneState)
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
                Button("Snapshot") {
                    sceneState.shouldTakeSnapshot = true
                }
            }
        }
        .onAppear {
            loadObj()
        }
    }
    
    func loadObj() {
        let fileName = "ANC101.step"
//        let fileName = "engine.stp"
        guard let newModel = modelStore.load(name: fileName)?.modelNode else {
            print("Couldn't load obj.")
            return
        }
        sceneState.name = fileName
        sceneState.model = newModel.normalized()
    }
}

#Preview {
    PreviewContainer()
}
