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
        guard let node = model?.modelNode,
              let geometry = node.geometry else { return }
        
        let elements = geometry.elements
        elements.forEach { element in
            let faces = element.data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Int32] in
                guard let boundPtr = ptr.baseAddress?.assumingMemoryBound(to: Int32.self) else { return [] }
                let buffer = UnsafeBufferPointer(start: boundPtr, count: element.data.count / 4)
                return Array<Int32>(buffer)
            }
            
            // Process face indices in groups of 3 (triangles)
            for i in stride(from: 0, to: faces.count, by: 3) {
                let i1 = faces[i]
                let i2 = faces[i + 1]
                let i3 = faces[i + 2]
                print("f \(i1)/\(i1) \(i2)/\(i2) \(i3)/\(i3)")
            }
        }
        
//        // Get face indices
//        let elements = geometry.elements
//        elements.forEach { element in
//            let data = element.data
//            let indexCount = element.primitiveCount * element.primitiveRange.length
//            
//            // Read face indices
//            var indices = [UInt32](repeating: 0, count: indexCount)
//            indices.withUnsafeMutableBytes { buffer in
//                data.copyBytes(to: buffer, count: indexCount * MemoryLayout<UInt32>.size)
//            }
//            
//            // Process face indices in groups of 3 (triangles)
//            for i in stride(from: 0, to: indices.count, by: 3) {
//                let i1 = indices[i]
//                let i2 = indices[i + 1]
//                let i3 = indices[i + 2]
//                print("Face: \(i1)/\(i2)/\(i3)")
//            }
//        }
        
        return
        // let elements = geometry.elements
        
        for element in elements {
            let faces = element.data.withUnsafeBytes {(ptr: UnsafeRawBufferPointer) -> [Int32] in
                guard let boundPtr = ptr.baseAddress?.assumingMemoryBound(to: Int32.self) else {return []}
                let buffer = UnsafeBufferPointer(start: boundPtr, count: element.data.count / 4)
                return Array<Int32>(buffer)
            }
            print(faces)
        }
        
        return
        // let elements = geometry.elements
        for element in elements {
            if element.primitiveType == .triangles {
                print(element.data.indices)
            } else {
                print(element.primitiveType)
            }
        }
        
        return
        // Get vertices
        let vertexSource = geometry.sources(for: .vertex).first
        let vertexCount = vertexSource?.vectorCount ?? 0
        let vertexStride = vertexSource?.dataStride ?? 0
        
        var vertices: [SCNVector3] = []
        vertexSource?.data.withUnsafeBytes { buffer in
            let vertexBuffer = buffer.bindMemory(to: Float.self)
            for i in 0..<vertexCount {
                let offset = i * vertexStride / MemoryLayout<Float>.size
                let x = vertexBuffer[offset + 0]
                let y = vertexBuffer[offset + 1]
                let z = vertexBuffer[offset + 2]
                vertices.append(SCNVector3(x, y, z))
            }
        }
        
        // Get triangle indices
        guard let element = geometry.elements.first else { return }
        let indexCount = element.data.count / MemoryLayout<UInt32>.size
        guard indexCount % 3 == 0 else { return } // Ensure we have complete triangles
        
        var triangles: [[UInt32]] = []
        triangles.reserveCapacity(indexCount / 3)
        
        element.data.withUnsafeBytes { buffer in
            let indexBuffer = buffer.bindMemory(to: UInt32.self)
            for i in stride(from: 0, to: indexCount, by: 3) {
                let triangle = [
                    indexBuffer[i],
                    indexBuffer[i + 1],
                    indexBuffer[i + 2]
                ]
                triangles.append(triangle)
            }
        }
        
        for (index, vertex) in vertices.enumerated() {
            print("\(String(format: "%4d", index)): v \(vertex.x) \(vertex.y) \(vertex.z)")
        }
        for (index, triangle) in triangles.enumerated() {
            print("\(String(format: "%4d", index)): f \(triangle[0]) \(triangle[1]) \(triangle[2])")
        }
        
//        struct GeometryGroup {
//            let name: String
//            let triangles: [[UInt32]]
//        }
//        
//        // Get groups and their triangles
//        var groups: [GeometryGroup] = []
//        
//        for (elementIndex, element) in geometry.elements.enumerated() {
//            let indexCount = element.data.count / MemoryLayout<UInt32>.size
//            guard indexCount % 3 == 0 else { continue }
//            
//            var triangles: [[UInt32]] = []
//            triangles.reserveCapacity(indexCount / 3)
//            
//            element.data.withUnsafeBytes { buffer in
//                let indexBuffer = buffer.bindMemory(to: UInt32.self)
//                for i in stride(from: 0, to: indexCount, by: 3) {
//                    let triangle = [
//                        indexBuffer[i],
//                        indexBuffer[i + 1],
//                        indexBuffer[i + 2]
//                    ]
//                    triangles.append(triangle)
//                }
//            }
//            
//            // Get group name from material or use default
//            let materialName = elementIndex < geometry.materials.count
//                ? geometry.materials[elementIndex].name ?? "group\(elementIndex)"
//                : "group\(elementIndex)"
//                
//            groups.append(GeometryGroup(name: materialName, triangles: triangles))
//        }
//        
//        for group in groups {
//            print("\ng \(group.name)")
//            for (index, triangle) in group.triangles.enumerated() {
//                print(String(format: "%4d: f %d %d %d", index, triangle[0], triangle[1], triangle[2]))
//            }
//        }
        
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
