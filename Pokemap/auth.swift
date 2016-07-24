//
//  auth.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation

protocol Auth {
    func getAccessToken(_ username: String, password: String, completion: (token: String?, error: NSError?) -> ())
    static func getAuthProvider() -> String
}

extension NSError {
    
    static func errorWithCode(_ code: Int, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: "pokemongoswiftapi.catch.em", code: code, userInfo: userInfo)
    }
    
    
}
