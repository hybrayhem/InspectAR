//
//  ModelSetupView+File.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import Alamofire
import UniformTypeIdentifiers

extension ModelSetupView {
    func handleFile(result: Result<[URL], Error>) {
        switch result {
        case .success(let files):
            guard let fileUrl = files.first else { return } // get file url
            selectedFile = fileUrl
            
        case .failure(let error):
            print(error)
        }
    }
    
    func uploadFile(fileUrl: URL) { // States: isUploading, isUploadComplete, uploadProgress
        isUploading = true
        guard let (fileName, fileData) = readFileData(fileUrl: fileUrl) else { return }
        
//#if targetEnvironment(simulator)
//        let serverUrl = "http://localhost:31415/stepToObj"
//#else
//        let serverUrl = "http://cadprocessor.local:31415/stepToObj"
//#endif
        let endpointUrl = Constants.API.baseURL + "/stepToObj"
        
        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(
                    fileData,
                    withName: "file",
                    fileName: fileName,
                    mimeType: "model/step"
                )
            },
            to: endpointUrl
        )
        .validate()
        .uploadProgress { progress in
            print("Progress: \(progress.fractionCompleted)")
        }
        .responseData { response in
            switch response.result {
            case .success(let responseData):
                print("Response data size: \(responseData.count)")
            case .failure(let error):
                print("File upload failed: \(error)")
            }
        }
    }
    
    func readFileData(fileUrl: URL) -> (String, Data)? {
        // Get file data
        var data: Data
        
        guard fileUrl.startAccessingSecurityScopedResource() else { // gain access to the directory
            print("Can't access to resource: \(fileUrl.absoluteString)")
            return nil
        }
        do {
            data = try Data(contentsOf: fileUrl)
            print("Data size: \(data.count)")
        } catch {
            print("Failed to read \(fileUrl.lastPathComponent): \(error)")
            return nil
        }
        fileUrl.stopAccessingSecurityScopedResource() // release access
        
        // Get file name
        let name = fileUrl.lastPathComponent
        
        return (name, data)
    }
}

extension UTType {
    static var stepExtensionType: UTType {
        UTType(filenameExtension: "step")!
    }
    
    static var stpExtensionType: UTType {
        UTType(filenameExtension: "stp")!
    }
    
    // Defines both .step and .stp
    static var stepImportType: UTType {
        UTType(importedAs: "public.step")
    }
}
