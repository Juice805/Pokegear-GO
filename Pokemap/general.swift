//
//  general.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON



// TODO: Find out what userAgent is
func getRequestsSession(_ userAgent: String? = nil) -> Manager {
    // Create the server trust policies
    let serverTrustPolicies: [String: ServerTrustPolicy] = [
        "nianticlabs.com": .disableEvaluation,
        "skiplagged.com": .disableEvaluation
    ]
    
    // Create custom manager
    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = Alamofire.Manager.defaultHTTPHeaders
    configuration.httpAdditionalHeaders!["User-Agent"] = userAgent
    
    print("JUICE- ADDITIONAL HEADERS"+configuration.httpAdditionalHeaders!.debugDescription)
    let man = Alamofire.Manager(
        configuration: configuration,
        serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
    )
    
    return man

}

func shortTime() -> String {
    return DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
}

func printTimestamped(_ text: String) {
    print("[" + shortTime() + "] " + text)
}

enum PokemapError: ErrorProtocol {
    case emptyUsername
    case emptyPassword
    case notLoggedIn
    case pDataAPI
    case specificAPIEndpoint
    case invalidJSON
    case expectedJSONKey
    case noProfileData
    
    var error: NSError {
        switch self {
        case .emptyUsername:
            return NSError.errorWithCode(1, failureReason: "Username cannot be empty")
        case .emptyPassword:
            return NSError.errorWithCode(2, failureReason: "Password cannot be empty")
        case .notLoggedIn:
            return NSError.errorWithCode(0, failureReason: "Must be logged in")
        case .pDataAPI:
            return NSError.errorWithCode(11, failureReason: "Failed to get PData")
        case .specificAPIEndpoint:
            return NSError.errorWithCode(10, failureReason: "Failed to get specific API endpoint")
        case .invalidJSON:
            return NSError.errorWithCode(3, failureReason: "Invalid JSON response")
        case .expectedJSONKey:
            return NSError.errorWithCode(4, failureReason: "Expected JSON key but did not exist")
        case .noProfileData:
            return NSError.errorWithCode(12, failureReason: "No Profile data received")
        }
    }
    
    
    var description: String { return self.error.debugDescription }
}


enum stringResult{
    case Success(String?)
    case Failure(NSError)
}

enum jsonResult{
    case Success([String: AnyObject]?)
    case Failure(NSError)
}

enum anyResult{
    case Success(AnyObject?)
    case Failure(NSError)
}


extension NSError {
    
    static func errorWithCode(_ code: Int, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: "pokemongoswiftapi.catch.em", code: code, userInfo: userInfo)
    }
    
    
}
