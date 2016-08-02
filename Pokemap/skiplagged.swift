//
//  skiplagged.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import Alamofire

class Skiplagged {
    static let API_SKIPLAGGED = "http://skiplagged.com/api/pokemon.php"
    static let API_GENERAL = "https://pgorelease.nianticlabs.com/plfe/rpc"
    internal var API_SPECIFIC: String?
    internal var PROFILE: [String: AnyObject]?
    internal var PROFILE_RAW: String?

    //MARK: - LOGIN

    internal (set) var accessToken: String?
    internal (set) var authProvider: String?
    internal (set) var username: String?
    internal (set) var password: String?
	var inhibitScan = true
	var scanInProgress = false

    var skiplaggedSession: Manager
    var nianticSession: Manager


    init() {
        nianticSession = getRequestsSession("Niantic App")
        skiplaggedSession = getRequestsSession("pokemongo-python")
    }

	func initializeConnection(completion: () -> ()) {
		DispatchQueue.global(qos: .background).async {
			while !self.getSpecificAPIEndpoint().success {
				Thread.sleep(forTimeInterval: 1.0)
				printTimestamped("Unable to retrieve specific endpoint. Retrying...")
			}

			while !self.getProfile().success {
				Thread.sleep(forTimeInterval: 1.0)
				printTimestamped("Unable to retrieve profile. Retrying...")
			}

			completion()
		}
	}



    func updateLogin(_ provider: String, token: String?, username: String, password: String) -> (String)? {
        if token != nil {
            self.authProvider = provider
            self.accessToken = token!
            self.username = username
            self.password = password

            return self.accessToken!
        } else {
            return nil
        }
    }

    func isLoggedOn() -> Bool {
        if self.accessToken != nil { return true } else { return false}
    }


    var currentReq = DispatchQueue(label: "Skiplagged")

	func cancelSearch(cancelled: () -> ()) {
		DispatchQueue.global(qos: .background).async {
			if self.scanInProgress {
				self.inhibitScan = true
				while self.inhibitScan {

				}

				cancelled()
			}
        }
    }

	func cancelScan(completion: () -> ()) {
		// TODO: 
	}
}
