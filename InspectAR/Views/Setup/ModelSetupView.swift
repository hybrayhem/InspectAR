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
    let modelStore = ModelStore()
    
    init(model: Model? = nil) {
        //        self.model = model
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
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // File Picker
            HStack {
                // file name
                HStack {
                    if selectedFile != nil {
                        Image(systemName: "cube")
                            .imageScale(.medium)
                    }
                    Text(selectedFile?.lastPathComponent ?? "Select a STEP file")
                }
                .padding(.leading, 40)
                
                Spacer()
                
                // file button
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
                            if let node = model?.modelNode?.normalized() {
                                sceneState.model = node
                            }
                            // Animation
                            sceneState.isAnimating = false // FIX: Remove workaround
                            DispatchQueue.main.async {
                                sceneState.isAnimating = true
                            }
                            // Snapshot
                            sceneState.shouldTakeSnapshot = true
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
                            sceneState.shouldResetCameraPose = true
                        } label: {
                            Image(systemName: "house.circle.fill")
                                .imageScale(.large)
                                .padding()
                        }
                        Spacer()
                        //  4. TODO: Implement face coloring
//                        Button {
//                            print("swatchpalette")
//                            // sceneState.enableFaceColors = true
//                        } label: {
//                            Image(systemName: "swatchpalette") // "swatchpalette.fill"
//                                .imageScale(.medium)
//                                .padding()
//                        }
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
            .disabled(isUploadDisabled)
        }
        .padding()
        .navigationTitle(selectedFile?.lastPathComponent ?? "New Model")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func handleNextButton() {
        print("Next button")
    }
    
    private func handleUploadButton() {
        guard let selectedFile = selectedFile else { return print("Selected file is nil.") }
        isUploading = true
        
        let group = DispatchGroup()
        Task {
            await handleUploadStep(file: selectedFile, group)
        }
        handleGetObj(group)
        handleGetFaceTriMap(group)
        
        group.notify(queue: .main) {
            loadNewModel()
            
            isUploading = false
            isUploadComplete = true
        }
    }
    
    private func handleUploadStep(file: URL, _ group: DispatchGroup) async {
        group.enter()
        uploadStep(stepUrl: file) { fileName in
            guard let fileName else {
                group.leave()
                return print("Failed to upload step file.")
            }
            print("Uploaded step file: \(fileName).")
            
            sceneState.name = fileName
            group.leave()
        }
    }
    
    private func handleGetObj(_ group: DispatchGroup) {
        guard let fileName = sceneState.name else { return }
        
        group.wait()
        group.enter()
        getObj(for: fileName) { success in
            if success {
                print("Successfully retrieved and saved obj file.")
            } else {
                print("Failed to retrieve obj file.")
            }
            group.leave()
        }
    }
    
    private func handleGetFaceTriMap(_ group: DispatchGroup) {
        guard let fileName = sceneState.name else { return }
        
        group.wait()
        group.enter()
        getFaceTriMap(for: fileName) { success in
            if success {
                print("Successfully retrieved and saved json file.")
            } else {
                print("Failed to retrieve json file.")
            }
            group.leave()
        }
    }
    
    private func loadNewModel() {
        guard let fileName = sceneState.name else { return }
        
        guard let newModel = modelStore.load(name: fileName) else {
            print("Couldn't load obj: \(fileName).")
            return
        }
        self.model = newModel
    }
    //        guard let newModel = modelStore.load(name: fileName)?.modelNode else {
    //            print("Couldn't load obj: \(fileName).")
    //            return
    //        }
    //        sceneState.model = newModel.normalized()
    // }
}

#Preview {
    ModelSetupView()
}
