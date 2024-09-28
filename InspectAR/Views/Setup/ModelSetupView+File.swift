//
//  ModelSetupView+File.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import UniformTypeIdentifiers

extension ModelSetupView {
    func handlePickedFile(result: Result<[URL], Error>) {
        switch result {
        case .success(let files):
            guard let fileUrl = files.first else { return } // get file url
            selectedFile = fileUrl
            
        case .failure(let error):
            print(error)
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
