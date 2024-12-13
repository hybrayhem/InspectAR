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
        .uploadProgress { progress in
            print("Progress: \(progress.fractionCompleted)")
            uploadProgress = progress.fractionCompleted
        }
        .validate()
        .responseData { response in
            switch response.result {
            case .success(let responseData):
                print("Response data size: \(responseData.count)")
                
                // Save obj
                do { try modelStore.save(name: fileName, obj: responseData) }
                catch { print("Failed to save obj: \(error)") }
                
            case .failure(let error):
                print("File upload failed: \(error)")
            }
            
            isUploading = false
            isUploadComplete = true
        }
    }
    
    func uploadStep(stepUrl: URL, completion: @escaping (String?) -> Void) {
        guard let (fileName, fileData) = readFileData(fileUrl: stepUrl) else { return completion(nil) }
        
        let endpointUrl = Constants.API.baseURL + "/uploadStep"
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
            case .success(let data):
                let fileName = String(data: data, encoding: .utf8)
                completion(fileName)
            case .failure(let error):
                print("File upload failed: \(error)")
                completion(nil)
            }
        }
    }
    
    func getObj(for fileName: String, completion: @escaping (Bool) -> Void) {
        let endpointUrl = Constants.API.baseURL + "/getObj"
        let parameters: [String: Any] = ["fileName": fileName]
        
        AF.request(endpointUrl, parameters: parameters)
        .validate()
        .responseData { response in
            switch response.result {
            case .success(let responseData):
                print("Response data size: \(responseData.count)")
                
                // Save obj
                do {
                    try modelStore.save(name: fileName, obj: responseData)
                    completion(true)
                } catch {
                    print("Failed to save obj: \(error)")
                    completion(false)
                }
                
            case .failure(let error):
                print("Failed to get obj: \(error)")
                completion(false)
            }
        }
    }
    
    func getFaceTriMap(for fileName: String, completion: @escaping (Bool) -> Void) {
        let endpointUrl = Constants.API.baseURL + "/getFaceTriMap"
        let parameters: [String: Any] = ["fileName": fileName]
        
        AF.request(endpointUrl, parameters: parameters)
        .validate()
        .responseData { response in
            switch response.result {
            case .success(let data):
                print("Response length: \(data.count)")
                
                // Save JSON
                do {
                    try modelStore.save(name: fileName, json: data)
                    completion(true)
                } catch {
                    print("Failed to save json: \(error)")
                    completion(false)
                }
                
            case .failure(let error):
                print("Failed to get json: \(error)")
                completion(false)
            }
        }
    }
}
