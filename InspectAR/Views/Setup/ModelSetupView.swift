//
//  ModelSetupView.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI
import SceneKit

enum AlignmentMethod: String, CaseIterable {
    case manual = "Manual"
    case marker = "Marker"
    case point = "4-Point"
    case automatic = "Automatic"
}

// TODO: Refactor model upload
struct ModelSetupView: View {
    // MARK: - States
    @State internal var selectedFile: URL?
    @State private var isShowingFilePicker = false
    //
    @State private var alignmentMethod = AlignmentMethod.manual
    //
    @State internal var isUploading = false
    @State internal var uploadProgress: Double = 0.0
    @State internal var isUploadComplete = false
    //
    @StateObject private var sceneState: SceneState = SceneState()
    //
    @State private var model: Model?
    @State private var isModelColored = false
    @State private var navigateToNext = false
    
    // MARK: - Properties
    let modelStore = ModelStore()
    
    // MARK: - Methods
    init(model: Model? = nil) {
        self._model = State(initialValue: model)
        if let model {
            self._selectedFile = State(initialValue: URL(string: model.name))
            self._isUploadComplete = State(initialValue: true)
        }
    }
    
    private var isUploadDisabled: Bool {
        selectedFile == nil || isUploading
    }
    
    private var uploadButtonColor: Color {
        isUploadDisabled ? .gray : (isUploadComplete ? .blue : .green)
    }
    
    private var scaledNode: SCNNode? {
        let node = model?.scnNode
        let s = 0.001
        node?.scale = SCNVector3(s, s, s)
        // node?.eulerAngles.x = Float(Double.pi / 2)
        return node
    }

    // MARK: - Views
    // file name
    private var fileNameSection: some View {
        HStack {
            if selectedFile != nil {
                Image(systemName: "cube")
                    .imageScale(.medium)
            }
            Text(selectedFile?.lastPathComponent ?? "Select a STEP file")
        }
        .padding(.leading, 40)
    }
    
    // file button
    private var filePickerButton: some View {
        Button {
            if selectedFile == nil {
                isShowingFilePicker = true
            } else {
                selectedFile = nil
                isUploadComplete = false
            }
        } label: {
            if selectedFile == nil {
                Image(systemName: "arrow.up.doc.fill")
                    .imageScale(.large)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            } else {
                Image(systemName: "x.circle")
                    .imageScale(.large)
                    .padding(12)
            }
        }
        .padding(.vertical)
        .padding(.trailing, 32)
        // file importer
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.stepExtensionType, .stpExtensionType], // .stepImportType, .item
            allowsMultipleSelection: false,
            onCompletion: handlePickedFile
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // File Picker
            HStack {
                fileNameSection
                Spacer()
                filePickerButton
            }
            // file background
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10, 2]))
            )
            
            // Alignment Method
            HStack {
                Text("Alignment Method")
                    .padding(.leading, 40)
                
                Spacer()
                
                Picker("Alignment Method", selection: $alignmentMethod) {
                    ForEach(AlignmentMethod.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.trailing)
            }
            
            Spacer()
            Spacer()
            
            // Upload Area / 3D Preview
            ZStack {
                // background
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.gray.opacity(0.2))
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fill)
                
                if isUploading {
                    VStack(spacing: 16) {
                        ProgressView(value: uploadProgress)
                            .progressViewStyle(CircularProgressViewStyle())
                            .controlSize(.large)
                        Text("Uploading STEP to server... %\(Int(uploadProgress * 100))")
                        // Text("Converting STEP to OBJ...")
                        // Text("Extracting face to triangle map...")
                        // Text("Retrieving OBJ and □ - ▲ map...")
                    }
                } else if isUploadComplete {
                    ModelPreviewView(sceneState: sceneState)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fill)
                        .cornerRadius(25)
                        .onAppear() {
                            print("Setting up model preview.")
                            // Model
                            sceneState.name = model?.name
                            if let node = model?.scnNode?.normalized() {
                                sceneState.scnNode = node
                            }
                            sceneState.isAnimating = true
                            
                            // Snapshot
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                                sceneState.currentAction = .takeSnapshot
                            }
                        }
                        .onDisappear() {
                            sceneState.isAnimating = false
                            sceneState.scnNode = SCNNode() // clear
                        }
                } else {
                    Text("No file to preview.")
                        .foregroundColor(.gray)
                }
                
                // corner buttons
                VStack{
                    HStack{
                        Button {
                            sceneState.isAnimating = true
                            sceneState.currentAction = .resetCamera
                        } label: {
                            Image(systemName: "house.circle.fill")
                                .imageScale(.large)
                                .padding()
                        }
                        Spacer()
                        Button {
                            let node = sceneState.scnNode

                            let colorOperation: (SCNGeometry?) -> SCNGeometry? = isModelColored 
                            // clear
                            ? { $0?.clearColors() }
                            // colorize
                            : { geometry in
                                guard let counts = model?.vertexCounts else { return nil }
                                return geometry?.colorizeElementsRandom(vertexCounts: counts)
                            }
                            
                            if let newGeometry = colorOperation(node.geometry) {
                                node.geometry = newGeometry
                                sceneState.scnNode = node
                                isModelColored.toggle()
                            }
                        } label: {
                            Image(systemName: isModelColored ? "swatchpalette.fill" : "swatchpalette")
                                .imageScale(.medium)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
            .padding(10)
            
            Spacer()
            
            // Upload / Next Button
            Button(action: {
                isUploadComplete ? handleNextButton() : handleUploadButton()
            }) {
                Text(isUploadComplete ? "Next" : "Upload")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(uploadButtonColor)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .navigationDestination(isPresented: $navigateToNext,
                                   destination: {
                MainARView(scnNode: scaledNode ?? SCNNode(), vertexCounts: model?.vertexCounts ?? [])
            })
            .disabled(isUploadDisabled)

        }
        .padding()
        .navigationTitle(selectedFile?.lastPathComponent ?? "New Model")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func handleNextButton() {
        print("Next button")
        navigateToNext = true
    }
    
    private func handleUploadButton() {
        guard let selectedFile = selectedFile else { return print("Selected file is nil.") }
        isUploading = true
        isUploadComplete = false
        
        uploadStep(stepUrl: selectedFile) { fileName in
            guard let fileName else {
                isUploading = false
                return print("Failed to upload step file.")
            }
            print("Uploaded step file: \(fileName).")
            
            getObj(for: fileName) { success in
                guard success else {
                    isUploading = false
                    return print("Failed to retrieve obj file.")
                }
                print("Successfully retrieved and saved obj file.")
                
//                getFaceTriMap(for: fileName) { success in
//                    guard success else {
//                        isUploading = false
//                        return print("Failed to retrieve json file.")
//                    }
//                    print("Successfully retrieved and saved json file.")
                    
                    loadNewModel(fileName: fileName)
                    isUploading = false
                    isUploadComplete = true
//                }
            }
        }

    }
    
    private func loadNewModel(fileName: String) {
        guard let newModel = modelStore.load(name: fileName) else {
            print("Couldn't load obj: \(fileName).")
            return
        }
        self.model = newModel
    }
}

#Preview {
    ModelSetupView()
}
