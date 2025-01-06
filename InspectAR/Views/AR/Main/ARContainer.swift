//
//  ARContainer.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI
import ARKit
//import SceneKit
import RealityKit

struct ARContainerRepresentable: UIViewControllerRepresentable {
    var objectToPlace: SCNNode?
    
    func makeUIViewController(context: Context) -> ARContainer {
        let controller = ARContainer()
        if let object = objectToPlace {
            controller.objectToPlace = object
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ARContainer, context: Context) {
        if let object = objectToPlace {
            uiViewController.objectToPlace = object
        }
    }
}

class ARContainer: UIViewController, ARSCNViewDelegate {
    // Views
    internal var sceneView: ARSCNView?
    internal var session: ARSession? { sceneView?.session }
    // Objects
    var objectToPlace: SCNNode?
    internal var placementIndicator: SCNNode?
    internal var shadowObject: SCNNode?
    // States
    internal var isPlacementValid = false {
        didSet {
            placementIndicator?.isHidden = !isPlacementValid
            
            shadowObject?.isHidden = !isPlacementValid
            sceneView?.debugOptions = !isPlacementValid ? [] : [.showBoundingBoxes]
        }
    }
    
    // MARK: - Init
//    init(objectToPlace: SCNNode) {
//        self.objectToPlace = objectToPlace
//        super.init(nibName: nil, bundle: nil)
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAR()
        setupCoaching()
        setupObjects()
        setupGestures()
    }
    
    private func setupAR() {
        // Initialize AR Scene View
        sceneView = ARSCNView(frame: view.bounds) // sceneView.frame = view.bounds
        guard let sceneView else { return }
        
        view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.rendersMotionBlur = true
        // sceneView.showsStatistics = true
        // sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = .horizontal // .vertical, .any
//        session?.run(configuration) // , options: [.resetTracking, .removeExistingAnchors])
        
        // Setup constraints
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupCoaching() {
        guard let sceneView else { return }
        
        let coachingOverlay = ARCoachingOverlayView(frame: view.bounds)
        sceneView.addSubview(coachingOverlay)
        coachingOverlay.session = session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.activatesAutomatically = true

        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            coachingOverlay.topAnchor.constraint(equalTo: sceneView.topAnchor),
            coachingOverlay.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor),
            coachingOverlay.leadingAnchor.constraint(equalTo: sceneView.leadingAnchor),
            coachingOverlay.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor)
        ])
    }
    
    private func setupObjects() {
        guard let sceneView else { return }
        
        // Setup object to place
        if objectToPlace == nil {
            let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
            objectToPlace = SCNNode(geometry: boxGeometry)
        }
        
        // Create placement indicator
        var objectWidth: Float = 0.15, objectLength: Float = 0.15
        if let objectToPlace {
            objectWidth = (objectToPlace.boundingBox.max.x - objectToPlace.boundingBox.min.x) / 500
            objectLength = (objectToPlace.boundingBox.max.y - objectToPlace.boundingBox.min.y) / 500
        }
        let indicatorGeometry = SCNGeometry.frame(width: CGFloat(objectWidth), length: CGFloat(objectLength))
        
        let material = SCNMaterial()
        // material.diffuse.contents = UIImage(systemName: "viewfinder", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100))
        material.diffuse.contents = UIColor.blue.withAlphaComponent(0.8)
        // material.isDoubleSided = true
        // material.transparency = 0.95
        indicatorGeometry.materials = [material]
        
        let indicator = SCNNode(geometry: indicatorGeometry)
        indicator.eulerAngles.x = -.pi / 2
        indicator.isHidden = true
        
        placementIndicator = indicator
        sceneView.scene.rootNode.addChildNode(indicator)
        
        // Create shadow object
        if let shadowObject = objectToPlace?.clone() {
            shadowObject.opacity = 0.5
            let s = 0.001 // Remove
            shadowObject.scale = .init(s, s, s) // Remove
            shadowObject.isHidden = true
            
            self.shadowObject = shadowObject
            sceneView.scene.rootNode.addChildNode(shadowObject)
        }
        
        isPlacementValid = false
    }
    
    private func setupGestures() {
        guard let sceneView else { return }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure AR Session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal // .vertical, .any
        session?.run(configuration) // , options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        session?.pause()
    }
    
    // MARK: - Actions
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let sceneView,
              let placementIndicator else { return }
        
        // Cast the ray
        guard let query = sceneView.raycastQuery(
            from: view.center,
            allowing: .estimatedPlane,
            alignment: .horizontal
        ),
        let result = sceneView.session.raycast(query).first else {
            isPlacementValid = false
            return
        }
        isPlacementValid = true
        
        // Position the indicator
        let position = SCNVector3(
            result.worldTransform.columns.3.x,
            result.worldTransform.columns.3.y,
            result.worldTransform.columns.3.z
        )
        placementIndicator.position = position
        
        if let camera = sceneView.pointOfView {
            let cameraPosition = camera.worldPosition
            placementIndicator.look(at: cameraPosition, up: .init(0, 1, 0), localFront: .init(0, 0, -1))
            placementIndicator.eulerAngles.x = -.pi / 2
        }
//        let forward = SIMD3<Float>(
//            result.worldTransform.columns.2.x,
//            result.worldTransform.columns.2.y,
//            result.worldTransform.columns.2.z
//        )
//        let yAngle = atan2(forward.x, forward.z)
//        shadowObject?.eulerAngles.y = yAngle
        
        // Position the shadow
        shadowObject?.position = position
        shadowObject?.eulerAngles.z = placementIndicator.eulerAngles.z
    }
}
