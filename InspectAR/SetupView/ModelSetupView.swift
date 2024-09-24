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

struct ModelSetupView: View {
    @State private var selectedFile: URL?
    @State private var isShowingFilePicker = false
    //
    @State private var alignmentMethod = AlignmentMethod.manual
    //
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var isUploadComplete = false
    
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
                    isShowingFilePicker = true
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
                
            }
            // file background
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10, 2]))
            )
            .sheet(isPresented: $isShowingFilePicker) {
//                DocumentPicker(selectedFile: $selectedFile)
            }
            
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
                        Text("Uploading STEP to server...")
//                        Text("Converting STEP to OBJ...")
//                        Text("Extracting face to triangle map...")
//                        Text("Retrieving OBJ and f-t map...")
//                        Text("Retrieving OBJ and □ - ▲ map...")
                    }
//                } else if isUploadComplete {
//                    SceneView(scene: createScene(), options: [.allowsCameraControl, .autoenablesDefaultLighting])
//                    .frame(maxWidth: .infinity)
//                    .aspectRatio(1, contentMode: .fill)
//                    .cornerRadius(25)
                } else {
                    Text("No file to preview.")
                        .foregroundColor(.gray)
                }
            }
            .padding(10)
            
            Spacer()
            
            // Upload/Next Button
            Button(action: {
                if isUploadComplete {
                    print("Next button tapped")
                } else {
//                    uploadFile()
                }
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
    }
    
//    private func uploadFile() {
//        guard selectedFile != nil else { return }
//        isUploading = true
//        // Simulate upload process
//        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
//            uploadProgress += 0.1
//            if uploadProgress >= 1.0 {
//                timer.invalidate()
//                isUploading = false
//                isUploadComplete = true
//                uploadProgress = 0.0
//            }
//        }
//    }
}

#Preview {
    ModelSetupView()
}
