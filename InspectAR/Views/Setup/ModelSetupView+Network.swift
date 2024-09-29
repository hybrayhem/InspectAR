//
//  ModelSetupView+Network.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import Alamofire
import Foundation

extension ModelSetupView {
    func uploadStepForObj(stepUrl: URL) { // States: isUploading, isUploadComplete, uploadProgress
        isUploading = true
        guard let (fileName, fileData) = readFileData(fileUrl: stepUrl) else { return }
        
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
            uploadProgress = progress.fractionCompleted
        }
        .responseData { response in
            switch response.result {
            case .success(let responseData):
                print("Response data size: \(responseData.count)")
                
                // Save obj
                do { try ModelStore.saveModel(name: fileName, obj: responseData) }
                catch { print("Failed to save obj: \(error)") }
                
            case .failure(let error):
                print("File upload failed: \(error)")
            }
            
            isUploading = false
            isUploadComplete = true
        }
    }
}
