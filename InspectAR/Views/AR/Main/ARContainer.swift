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

enum ARState {
    case none
    case searchingPlane

    case placingObject
    case objectPlaced
    
    case inspectingObject
    case objectInspected
}

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
    internal var placeAt = SCNNode()
    internal var shadowObject: SCNNode?
    // States
    internal var state: ARState = .none {
        didSet {
            if oldValue != state { print("State: \(state)") }
            
            if state == .placingObject {
                shadowObject?.isHidden = false
                sceneView?.debugOptions = [.showBoundingBoxes]
            } else {
                shadowObject?.isHidden = true
                sceneView?.debugOptions = []
            }
        }
    }
    internal var stateLock = NSLock()
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAR()
        setupCoaching()
        setupObjects()
        setupGestures()
        
        stateLock.lock()
        state = .searchingPlane
        stateLock.unlock()
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
        coachingOverlay.delegate = self
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
        
        // Create shadow object
        if let shadowObject = objectToPlace?.clone() {
            shadowObject.opacity = 0.5
            shadowObject.isHidden = true
            
            self.shadowObject = shadowObject
            sceneView.scene.rootNode.addChildNode(shadowObject)
        }
    }
    
    private func setupGestures() {
        guard let sceneView else { return }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        sceneView.addGestureRecognizer(rotationGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        sceneView.addGestureRecognizer(panGesture)
    }
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure AR Session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal // .vertical, .any
        session?.run(configuration) // , options: [.resetTracking, .removeExistingAnchors])
        // state = .searchingPlane // This method doesn't changing the state
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        session?.pause()
        
        stateLock.lock()
        state = .none
        stateLock.unlock()
    }
    
    // MARK: - Actions
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let sceneView else { return }
        
        stateLock.lock()
        defer { stateLock.unlock() }
        switch state {
        case .searchingPlane, .placingObject:
            // Cast the ray
            guard let query = sceneView.raycastQuery(
                from: view.center,
                allowing: .estimatedPlane,
                alignment: .horizontal
            ),
            let result = sceneView.session.raycast(query).first else {
                state = .searchingPlane
                return
            }
            state = .placingObject
            
            // Get results
            let position = SCNVector3(
                result.worldTransform.columns.3.x,
                result.worldTransform.columns.3.y,
                result.worldTransform.columns.3.z
            )
            placeAt.position = position
            
            // if let camera = sceneView.pointOfView {
            //     placeAt.look(at: camera.worldPosition, up: .init(0, 1, 0), localFront: .init(0, 0, -1))
            // }
            
            // Position the shadow
            shadowObject?.position = placeAt.position
            
            // // Keep object parallel to camera
            // shadowObject?.eulerAngles.y = placeAt.eulerAngles.y
        default:
            break
        }
        stateLock.unlock()
    }
}
