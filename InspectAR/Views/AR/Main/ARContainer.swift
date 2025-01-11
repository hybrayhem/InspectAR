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
        setupButtons()
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
        sceneView.rendersCameraGrain = true
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
    
    private func setupButtons() {
        guard let sceneView else { return }
        
        let largeSymbol = UIImage.SymbolConfiguration(scale: .large)

        // Flashlight button
        let flashlightButton = UIButton()
        flashlightButton.setImage(UIImage(systemName: "flashlight.off.circle", withConfiguration: largeSymbol), for: .normal)
        flashlightButton.setImage(UIImage(systemName: "flashlight.on.circle", withConfiguration: largeSymbol), for: .selected)
        flashlightButton.layer.cornerRadius = 22
        flashlightButton.addTarget(self, action: #selector(toggleFlashlight), for: .touchUpInside)
        
        sceneView.addSubview(flashlightButton)
        flashlightButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            flashlightButton.widthAnchor.constraint(equalToConstant: 44),
            flashlightButton.heightAnchor.constraint(equalToConstant: 44),
            flashlightButton.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor, constant: -16),
            flashlightButton.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor, constant: -16)
        ])
        
        // Camera info button
        let cameraInfoButton = UIButton()
        cameraInfoButton.setImage(UIImage(systemName: "camera.badge.ellipsis.fill", withConfiguration: largeSymbol), for: .normal)
        cameraInfoButton.layer.cornerRadius = 22
        cameraInfoButton.addTarget(self, action: #selector(getCameraInfo), for: .touchUpInside)
        
        sceneView.addSubview(cameraInfoButton)
        cameraInfoButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraInfoButton.widthAnchor.constraint(equalToConstant: 44),
            cameraInfoButton.heightAnchor.constraint(equalToConstant: 44),
            cameraInfoButton.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor, constant: -16 - 44 - 4),
            cameraInfoButton.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor, constant: -16)
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
        configuration.isAutoFocusEnabled = true
        configuration.isLightEstimationEnabled = true
        if let format =  ARWorldTrackingConfiguration.recommendedVideoFormatForHighResolutionFrameCapturing {
            configuration.videoFormat = format
        }
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
    
    @objc func toggleFlashlight(sender: UIButton) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else {
            print("Device does not have a torch.")
            return
        }
        
        try? device.lockForConfiguration()
        let isOn = device.torchMode == .on
        device.torchMode = isOn ? .off : .on
        device.unlockForConfiguration()
        
        sender.isSelected = isOn
    }
    
    // TODO: Debug method, review later
    @objc func getCameraInfo(sender: UIButton) {
        guard let camera = sceneView?.pointOfView else { return }
        print("worldPosition: ", camera.worldPosition)
        
        let avCamera = sceneView?.session.currentFrame?.camera
        print("transform: ", avCamera?.transform.columns.3 ?? "nil")
        print("projectionMatrix: ", avCamera?.projectionMatrix(for: .portrait, viewportSize: .init(width: 100, height: 100), zNear: 0.1, zFar: 1000) ?? "nil")
        print("viewMatrix: ", avCamera?.viewMatrix(for: .portrait) ?? "nil")
        print("intrinsics: ", avCamera?.intrinsics ?? "nil")
        
        let depthData = sceneView?.session.currentFrame?.capturedDepthData
        print("cameraCalibrationData: ", depthData?.cameraCalibrationData ?? "nil")
        print("depthDataQuality: ", depthData?.depthDataQuality ?? "nil")
        
        // captured image
        let capturedImage = sceneView?.session.currentFrame?.capturedImage
        print("capturedImage size: ", UIImage(ciImage: CIImage(cvPixelBuffer: capturedImage!)).size)
        
        var capturedImageHighRes: CVPixelBuffer?
        sceneView?.session.captureHighResolutionFrame(completion: { frame, error in
            capturedImageHighRes = frame?.capturedImage

            let ciImage = CIImage(cvPixelBuffer: capturedImageHighRes!/*, options: [.applyOrientationProperty: true]*/).oriented(.right)
            
            // Show image
            let image = UIImage(ciImage: ciImage)
            print("capturedImageHighRes size: ", image.size)
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = self.view.bounds
            self.view.addSubview(imageView)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                imageView.removeFromSuperview()
            }
        })
    }

}
