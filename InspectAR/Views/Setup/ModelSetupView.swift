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
    @State internal var selectedFile: URL?
    @State private var isShowingFilePicker = false
    //
    @State private var alignmentMethod = AlignmentMethod.manual
    //
    @State internal var isUploading = false
    @State internal var uploadProgress: Double = 0.0
    @State internal var isUploadComplete = false
    //
    @StateObject private var sceneState = SceneState()
    
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
                    onCompletion: handleFile
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
//                        Text("Converting STEP to OBJ...")
//                        Text("Extracting face to triangle map...")
//                        Text("Retrieving OBJ and □ - ▲ map...")
                    }
                } else if isUploadComplete || true {
                    ModelPreviewView(sceneState: sceneState)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fill)
                    .cornerRadius(25)
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
                        // TODO:
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
            
            // Upload/Next Button
            Button(action: {
                if isUploadComplete {
                    print("Next button")
                } else {
                    // guard let selectedFile = selectedFile else {
                    //     print("Selected file is nil.")
                    //     return
                    // }
                    uploadFile(fileUrl: selectedFile!) // selectedFile is not nil, else button is disabled
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
}

#Preview {
    ModelSetupView()
}
