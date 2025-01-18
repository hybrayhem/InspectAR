//
//  ARContainer.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import ARKit
import SwiftUI
import SceneKit

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
    var vertexCounts: [Int]?
    
    func makeUIViewController(context: Context) -> ARContainer {
        let controller = ARContainer()
        if let object = objectToPlace {
            controller.objectToPlace = object
        }
        controller.vertexCounts = vertexCounts
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ARContainer, context: Context) {
        if let object = objectToPlace {
            uiViewController.objectToPlace = object
        }
    }
}

class ARContainer: UIViewController, ARSCNViewDelegate {
    var counter: Int = 0
    // Views
    internal var sceneView: ARSCNView?
    internal var session: ARSession? { sceneView?.session }
    // Objects
    var objectToPlace: SCNNode?
    var vertexCounts: [Int]?
    var initialObjectScale: SCNVector3?
    internal var shadowObject: SCNNode?
    internal var placeAt = SCNNode()
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
    // Gesture Variables
    internal var panOffset = SIMD3<Float>()
    internal var initialPanPosition: SIMD3<Float>?
    internal var currentScaleStepIndex = 4 // 2
    internal let scaleSteps: [Float] = [0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 10.0, 20.0, 100.0] // [0.01, 0.1, 1.0, 10.0, 100.0]
    
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
        
        // Run button
        let runButton = UIButton()
        runButton.setImage(UIImage(systemName: "play.fill", withConfiguration: largeSymbol), for: .normal)
        runButton.layer.cornerRadius = 22
        runButton.addTarget(self, action: #selector(apiInspection), for: .touchUpInside)
        
        sceneView.addSubview(runButton)
        runButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            runButton.widthAnchor.constraint(equalToConstant: 44),
            runButton.heightAnchor.constraint(equalToConstant: 44),
            runButton.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor, constant: -16 - 44 - 4 - 44 - 4),
            runButton.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor, constant: -16)
        ])
        
    }
    
    private func setupObjects() {
        guard let sceneView else { return }
        
        // Setup object to place
        if objectToPlace == nil {
            let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
            objectToPlace = SCNNode(geometry: boxGeometry)
        }
        initialObjectScale = objectToPlace?.scale
        
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
        
        // Create gestures
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        rotationGesture.delegate = self
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinchGesture.delegate = self
        
        let doublePanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDoublePan))
        doublePanGesture.minimumNumberOfTouches = 2
        doublePanGesture.delegate = self
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        
        // Set dependencies
        tapGesture.require(toFail: doubleTapGesture)
        
        // Add gestures
        [tapGesture, doubleTapGesture, rotationGesture, pinchGesture, doublePanGesture, panGesture].forEach {
            sceneView.addGestureRecognizer($0)
        }
    }
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure AR Session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal] // .vertical, .any
        configuration.isAutoFocusEnabled = true
        configuration.isLightEstimationEnabled = true
        
        if let format =  ARWorldTrackingConfiguration.recommendedVideoFormatForHighResolutionFrameCapturing {
            configuration.videoFormat = format
        }
        
        configuration.frameSemantics = [.personSegmentationWithDepth]
        // arView.environment.sceneUnderstanding.options.insert(.occlusion) // Only available in RealityKit
        
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
    
    // MARK: - Scene
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
    
    // MARK: - Actions
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
        
//        var capturedImageHighRes: CVPixelBuffer?
//        sceneView?.session.captureHighResolutionFrame(completion: { frame, error in
//            capturedImageHighRes = frame?.capturedImage
//            // capturedImageHighRes = capturedImage // DEBUG
//             // DEBUG
//
//            let ciImage = CIImage(cvPixelBuffer: capturedImageHighRes!/*, options: [.applyOrientationProperty: true]*/).oriented(.right)
//            
//            // Show image
//            let image = UIImage(ciImage: ciImage)
//            print("capturedImageHighRes size: ", image.size)
//            let imageView = UIImageView(image: image)
//            imageView.contentMode = .scaleAspectFit
//            imageView.frame = self.view.bounds
//            self.view.addSubview(imageView)
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                imageView.removeFromSuperview()
//            }
//        })
        
        print("Camera up: \(camera.worldUp)")
        print("Camera position: \(camera.worldPosition)")
        print("Camera orientation: \(camera.worldOrientation)")
        print("Camera transform: \(camera.worldTransform)")
        
        let object = sceneView?.scene.rootNode.childNode(withName: "placed-object", recursively: false)
        print("Object position: \(object?.worldPosition ?? SCNVector3())")
        print("Object orientation: \(object?.worldOrientation ?? SCNQuaternion())")
        
        if let object {
            let image = sceneView?.drawBoundingBoxOnCapturedImage(for: object)
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = self.view.bounds
            self.view.addSubview(imageView)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                imageView.removeFromSuperview()
            }
        }
    }
    
//    @objc func mockInspection(sender: UIButton) {
//        guard let vertexCounts,
//              let object = sceneView?.scene.rootNode.childNode(withName: "placed-object", recursively: false) else { return }
//        
//        object.geometry = object.geometry?.clearColors()
//        object.opacity = 1.0
//        showLoadingDialog()
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + ((self.counter % 2 == 0) ? 32 : 28)) {
//            object.geometry = (self.counter % 2 == 0)
//            ? object.geometry?.colorizeElementsAt(found: [0,1,2,4], missing: [], nonvisible: [3], vertexCounts: vertexCounts)
//            : object.geometry?.colorizeElementsAt(found: [0,1,2,3], missing: [4], nonvisible: [], vertexCounts: vertexCounts)
//            object.opacity = 0.8
//            
//            self.dismissLoadingDialog()
//            self.counter += 1
//        }
//    }
    
    @objc func apiInspection(sender: UIButton) {
        guard let sceneView,
              let camera = sceneView.pointOfView,
              let avCamera = sceneView.session.currentFrame?.camera,
              let object = sceneView.scene.rootNode.childNode(withName: "placed-object", recursively: false) else { return }
        
        object.geometry = object.geometry?.clearColors()
        object.opacity = 1.0
        
        // Camera Parameters
        let intrinsics = avCamera.intrinsics
        let fx = intrinsics.columns.0.x
        let fy = intrinsics.columns.1.y
        let cx = intrinsics.columns.2.x
        let cy = intrinsics.columns.2.y
        
        // Image
        guard let capturedImage = sceneView.session.currentFrame?.capturedImage else { return }
        let image = UIImage(ciImage: CIImage(cvPixelBuffer: capturedImage).oriented(.right))
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        
        // 2D Bounding Box of Object
        let boundingBox = sceneView.boundingBox2DInCapturedImage(for: object)
        print("Bounding Box: \(boundingBox ?? .zero)")
        
        // Relative Orientation of Object
        let cameraOrientation = camera.worldOrientation.toQuaternion()
        let objectOrientation = object.worldOrientation.toQuaternion()
        let relativeOrientation = cameraOrientation.inverse * objectOrientation
        let node = SCNNode()
        node.simdOrientation = relativeOrientation
        let relativeAngles = node.eulerAngles
        print("Relative Orientation: \(relativeAngles)")
        
        guard let boundingBox else { return }
        showLoadingDialog()
        inspectObject(fx, fy, cx, cy,
                          image, imageWidth, imageHeight,
                          [boundingBox.minX, boundingBox.minY, boundingBox.maxX, boundingBox.maxY],
                          [relativeAngles.x, relativeAngles.y, relativeAngles.z]) { result in
            print("Inspection result: \(result ?? "nil")")
            
//            object.geometry = object.geometry?.colorizeElementsAt(found: [0,1,2,4], missing: [], nonvisible: [3], vertexCounts: self.vertexCounts)
//            object.opacity = 0.8
            
            self.dismissLoadingDialog()
        }
    }

}

extension SCNQuaternion {
    // Convert SCNVector4 to quaternion representation
    func toQuaternion() -> simd_quatf {
        return simd_quatf(ix: Float(self.x),
                          iy: Float(self.y),
                          iz: Float(self.z),
                          r: Float(self.w))
    }
    
    // Create SCNVector4 from quaternion
    static func fromQuaternion(_ quaternion: simd_quatf) -> SCNVector4 {
        return SCNVector4(x: Float(CGFloat(quaternion.imag.x)),
                          y: Float(CGFloat(quaternion.imag.y)),
                          z: Float(CGFloat(quaternion.imag.z)),
                          w: Float(CGFloat(quaternion.real)))
    }
}

extension ARContainer {
    func showLoadingDialog() {
        // Create alert controller
        let alert = UIAlertController(title: nil, message: "Waiting inspection result...\n\n", preferredStyle: .alert)
        alert.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Add activity indicator
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        
        alert.view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: alert.view.centerYAnchor, constant: 16)
        ])
        
        present(alert, animated: true, completion: nil)
    }
    
    func dismissLoadingDialog() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Network
import Alamofire
extension ARContainer {
    func inspectObject(_ fx: Float, _ fy: Float, _ cx: Float, _ cy: Float,
                       _ image: UIImage, _ imageWidth: CGFloat, _ imageHeight: CGFloat,
                       _ boundingBox: [CGFloat], _ relativeAngles: [Float],
                       completion: @escaping (String?) -> Void)
    {
        let endpointUrl = Constants.API.baseURL + "/inspectObject"
        
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Error converting image to data")
            completion(nil)
            return
        }
        
        let boundingBoxStr = boundingBox.map { String(Float($0)) }.joined(separator: ", ")
        let relativeAnglesStr = relativeAngles.map { String($0) }.joined(separator: ", ")
        let parameters: [String: String] = [
            "fx": String(fx),
            "fy": String(fy),
            "cx": String(cx),
            "cy": String(cy),
            "imageWidth": String(Float(imageWidth)),
            "imageHeight": String(Float(imageHeight)),
            "boundingBox": boundingBoxStr,
            "relativeAngles": relativeAnglesStr
        ]
        
        AF.upload(
            multipartFormData: { multipartFormData in
                for (key, value) in parameters {
                    multipartFormData.append(Data(value.utf8), withName: key)
                }
                
                multipartFormData.append(imageData, withName: "file", fileName: "image.jpg", mimeType: "image/jpeg")
            },
            to: endpointUrl,
            method: .post
        ).responseData { response in
            let fail = { (message: String) in
                print(message)
                completion(nil)
            }
            
            switch response.result {
            case .success(let data):
                if let response = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let fileName = response["filename"] {
                    return completion(fileName)
                }
                fail("Failed to parse file name response")
            case .failure(let error):
                fail("File upload failed: \(error)")
            }
        }
        
    }
    
    func uploadImage(image: CGImage, completion: @escaping (String?) -> Void) {
//        guard let (fileName, fileData) = readFileData(fileUrl: stepUrl) else { return completion(nil) }
//        
//        let endpointUrl = Constants.API.baseURL + "/uploadStep"
//        AF.upload(
//            multipartFormData: { multipartFormData in
//                multipartFormData.append(
//                    fileData,
//                    withName: "file",
//                    fileName: fileName,
//                    mimeType: "model/step"
//                )
//            },
//            to: endpointUrl
//        )
//        .validate()
//        .uploadProgress { progress in
//            print("Progress: \(progress.fractionCompleted)")
//            uploadProgress = progress.fractionCompleted
//        }
//        .responseData { response in
//            let fail = { (message: String) in
//                print(message)
//                completion(nil)
//            }
//            
//            switch response.result {
//            case .success(let data):
//                if let response = try? JSONSerialization.jsonObject(with: data) as? [String: String],
//                   let fileName = response["filename"] {
//                    return completion(fileName)
//                }
//                fail("Failed to parse file name response")
//            case .failure(let error):
//                fail("File upload failed: \(error)")
//            }
//        }
    }
    
}

extension ARSCNView {
    func boundingBox2D(for node: SCNNode) -> CGRect? {
        // Get the node's bounding box in its local coordinate space
        let boundingBox = node.boundingBox
        let bmin = boundingBox.min
        let bmax = boundingBox.max
        
        // Get all corners of the bounding box
        let corners = [
            SCNVector3(bmin.x, bmin.y, bmin.z),
            SCNVector3(bmin.x, bmin.y, bmax.z),
            SCNVector3(bmin.x, bmax.y, bmin.z),
            SCNVector3(bmin.x, bmax.y, bmax.z),
            SCNVector3(bmax.x, bmin.y, bmin.z),
            SCNVector3(bmax.x, bmin.y, bmax.z),
            SCNVector3(bmax.x, bmax.y, bmin.z),
            SCNVector3(bmax.x, bmax.y, bmax.z)
        ]
        
        // Convert corners to screen space
        var minX: CGFloat = .infinity
        var maxX: CGFloat = -.infinity
        var minY: CGFloat = .infinity
        var maxY: CGFloat = -.infinity
        
        for corner in corners {
            // Convert the point from local node coordinates to world coordinates
            let worldPoint = node.convertPosition(corner, to: nil)
            
            // Project the world point to screen coordinates
            let projection = projectPoint(worldPoint)
            
            // Check if the point is in front of the camera
            guard projection.z > 0 else { continue }
            
            minX = min(minX, CGFloat(projection.x))
            maxX = max(maxX, CGFloat(projection.x))
            minY = min(minY, CGFloat(projection.y))
            maxY = max(maxY, CGFloat(projection.y))
        }
        
        // If we couldn't project any points, return nil
        guard minX != .infinity else { return nil }
        
        return CGRect(x: minX,
                     y: minY,
                     width: maxX - minX,
                     height: maxY - minY)
    }
    
    func boundingBox2DInCapturedImage(for node: SCNNode) -> CGRect? {
        guard let currentFrame = session.currentFrame else { return nil }
        
        // Get the node's bounding box in its local coordinate space
        let boundingBox = node.boundingBox
        let bmin = boundingBox.min
        let bmax = boundingBox.max
        
        // Get all corners of the bounding box
        let corners = [
            SCNVector3(bmin.x, bmin.y, bmin.z),
            SCNVector3(bmin.x, bmin.y, bmax.z),
            SCNVector3(bmin.x, bmax.y, bmin.z),
            SCNVector3(bmin.x, bmax.y, bmax.z),
            SCNVector3(bmax.x, bmin.y, bmin.z),
            SCNVector3(bmax.x, bmin.y, bmax.z),
            SCNVector3(bmax.x, bmax.y, bmin.z),
            SCNVector3(bmax.x, bmax.y, bmax.z)
        ]
        
        var minX: CGFloat = .infinity
        var maxX: CGFloat = -.infinity
        var minY: CGFloat = .infinity
        var maxY: CGFloat = -.infinity
        
        for corner in corners {
            // Convert corner from local node coordinates to world coordinates
            let worldPoint = node.convertPosition(corner, to: nil)
            
            // Convert world position to camera coordinates
            let point = currentFrame.camera.projectPoint(
                simd_float3(x: Float(worldPoint.x),
                           y: Float(worldPoint.y),
                           z: Float(worldPoint.z)),
                orientation: .portrait,
                viewportSize: currentFrame.camera.imageResolution)
            
            // The point is now in image coordinates (origin at top-left)
            minX = min(minX, CGFloat(point.x))
            maxX = max(maxX, CGFloat(point.x))
            minY = min(minY, CGFloat(point.y))
            maxY = max(maxY, CGFloat(point.y))
        }
        
        // If we couldn't project any points, return nil
        guard minX != .infinity else { return nil }
        
        return CGRect(x: minX,
                     y: minY,
                     width: maxX - minX,
                     height: maxY - minY)
    }
    
//    func boundingBox2DInCapturedImage(for node: SCNNode) -> CGRect? {
//        guard let currentFrame = session.currentFrame else { return nil }
//        
//        // Get the node's bounding box in its local coordinate space
//        let boundingBox = node.boundingBox
//        let bmin = boundingBox.min
//        let bmax = boundingBox.max
//        
//        // Get all corners of the bounding box
//        let corners = [
//            SCNVector3(bmin.x, bmin.y, bmin.z),
//            SCNVector3(bmin.x, bmin.y, bmax.z),
//            SCNVector3(bmin.x, bmax.y, bmin.z),
//            SCNVector3(bmin.x, bmax.y, bmax.z),
//            SCNVector3(bmax.x, bmin.y, bmin.z),
//            SCNVector3(bmax.x, bmin.y, bmax.z),
//            SCNVector3(bmax.x, bmax.y, bmin.z),
//            SCNVector3(bmax.x, bmax.y, bmax.z)
//        ]
//        
//        var minX: CGFloat = .infinity
//        var maxX: CGFloat = -.infinity
//        var minY: CGFloat = .infinity
//        var maxY: CGFloat = -.infinity
//        
//        // Get current camera transform
//        let viewMatrix = currentFrame.camera.viewMatrix(for: .portrait)
//        let projectionMatrix = currentFrame.camera.projectionMatrix(for: .portrait,
//                                                                    viewportSize: currentFrame.camera.imageResolution,
//                                                                    zNear: 0.001,
//                                                                    zFar: 1000)
//        
//        for corner in corners {
//            // Convert from local node space to world space
//            let worldPoint = node.presentation.convertPosition(corner, to: nil)
//            
//            // Convert to 4D homogeneous coordinate
//            var worldVector = simd_float4(Float(worldPoint.x),
//                                          Float(worldPoint.y),
//                                          Float(worldPoint.z),
//                                          1.0)
//            
//            // Transform to camera space
//            let cameraVector = viewMatrix * worldVector
//            
//            // Project to 2D
//            let projectedVector = projectionMatrix * cameraVector
//            
//            // Perspective division
//            guard projectedVector.w != 0 else { continue }
//            let normalizedVector = projectedVector / projectedVector.w
//            
//            // Convert to image coordinates
//            let imageSize = currentFrame.camera.imageResolution
//            let point = CGPoint(
//                x: CGFloat((normalizedVector.x + 1.0) * 0.5 * Float(imageSize.width)),
//                y: CGFloat((1.0 - normalizedVector.y) * 0.5 * Float(imageSize.height))
//            )
//            
//            minX = min(minX, point.x)
//            maxX = max(maxX, point.x)
//            minY = min(minY, point.y)
//            maxY = max(maxY, point.y)
//        }
//        
//        // If we couldn't project any points, return nil
//        guard minX != .infinity else { return nil }
//        
//        return CGRect(x: minX,
//                      y: minY,
//                      width: maxX - minX,
//                      height: maxY - minY)
//    }
    
    func drawBoundingBoxOnCapturedImage(for node: SCNNode) -> UIImage? {
        guard let currentFrame = session.currentFrame,
              let boundingBox = boundingBox2DInCapturedImage(for: node) else {
            return nil
        }
        
        // Convert CVPixelBuffer to CIImage
        let ciImage = CIImage(cvPixelBuffer: currentFrame.capturedImage)
        
        // Rotate the image 90 degrees clockwise
        let rotatedImage = ciImage.oriented(.right)
        
        // Create UIImage with the rotated CIImage
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(rotatedImage, from: rotatedImage.extent) else {
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        
        // Create a context with the rotated size
        UIGraphicsBeginImageContext(image.size)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Draw the rotated captured image
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        // Draw the bounding box
        context.setStrokeColor(UIColor.green.cgColor)
        context.setLineWidth(3.0)
        context.stroke(boundingBox)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
