//
//  auth.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation

protocol Auth {
    func getAccessToken(_ username: String, password: String, completion: (tokenResult: stringResult) -> ())
    static func getAuthProvider() -> String
}


