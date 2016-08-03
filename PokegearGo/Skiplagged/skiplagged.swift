//
//  skiplagged.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import Alamofire
import MapKit

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
	var inhibitScan = false
	var scanInProgress: ScanModes? = nil
	var cancelling = true

    var skiplaggedSession: Manager
    var nianticSession: Manager


    init() {
        nianticSession = getRequestsSession("Niantic App")
        skiplaggedSession = getRequestsSession("pokemongo-python")
    }

	var cancelLogin = false

	func initializeConnection(statusUpdate: ((LoginSteps) -> ())? = nil,
	                          canceled: (() -> ())? = nil,
	                          completion: () -> ()) {
		DispatchQueue.global(qos: .userInitiated).async {

			var specificEndpoint = self.getSpecificAPIEndpoint(statusUpdate: statusUpdate)

			while !specificEndpoint.success && !self.cancelLogin {
				Thread.sleep(forTimeInterval: 1.0)
				printTimestamped("Unable to retrieve specific endpoint. Retrying...")
				specificEndpoint = self.getSpecificAPIEndpoint(statusUpdate: statusUpdate)
			}

			var profile = self.getProfile(statusUpdate: statusUpdate)

			while !profile.success && !self.cancelLogin {
				Thread.sleep(forTimeInterval: 1.0)
				printTimestamped("Unable to retrieve profile. Retrying...")
				profile = self.getProfile(statusUpdate: statusUpdate)
			}

			if self.cancelLogin {
				self.cancelLogin = false
				if canceled != nil {
					canceled!()
				}
				return
			}

			completion()
		}
	}


    func updateLogin(_ provider: String? = nil, token: String? = nil, username: String? = nil, password: String? = nil) {

		self.authProvider = provider
		self.accessToken = token
		self.username = username
		self.password = password

        return
    }

    func isLoggedOn() -> Bool {
        if self.accessToken != nil { return true } else { return false}
    }

}

enum ScanModes {
	case Autoscan
	case Followscan
	case Manualscan
}

// swiftlint:disable:next variable_name
func == (a: ScanModes?, b: ScanModes?) -> Bool {
	switch (a, b) {
	case (.Autoscan?, .Autoscan?):
		return true
	case (.Followscan(_)?, .Followscan(_)?):
		return true
	case (.Manualscan?, .Manualscan?):
		return true
	default:
		return false
	}
}
