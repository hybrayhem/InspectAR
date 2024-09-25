//
//  Constants.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import Foundation

struct Constants {
    struct API {}
}

extension Constants.API {
    private static var plist: NSDictionary? {
        guard let filePath = Bundle.main.path(forResource: "CIAM-Info", ofType: "plist") else {
            preconditionFailure("Couldn't find file 'CIAM-Info.plist'.")
        }
        
        return NSDictionary(contentsOfFile: filePath)
    }
    
    static let baseURL: String = {
        guard let url = plist?.object(forKey: "API_URL") as? String else {
            preconditionFailure("API_URL not defined.")
        }
        return "http://" + url
    }()
}
