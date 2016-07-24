//
//  general.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import Alamofire


// TODO: Find out what userAgent is
func setRequestsSession(_ userAgent: String? = nil){
    let session = Alamofire.Manager.sharedInstance.session
    
    session.configuration.httpAdditionalHeaders!["User-Agent"] = userAgent
}

func shortTime() -> String {
    return DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
}

func printTimestamped(_ text: String) {
    print("[" + shortTime() + "] " + text)
}

enum PokemapErrors: ErrorProtocol {
    case emptyUsername
    case emptyPassword
    case notLoggedIn
    case pDataAPI
    case specificAPIEndpoint
    
    var description: String {
        switch self {
        case .emptyUsername:
            return "Username cannot be empty"
            
        case .emptyPassword:
            return "Password cannot be empty"
        case .notLoggedIn:
            return "Must be logged in"
        case .pDataAPI:
            return "Failed to get PData"
        case .specificAPIEndpoint:
            return "Failed to get specific API endpoint"
        }
    }
}
