//
//  google.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation

class Google: Auth {
	static func getAuthProvider() -> String {
		return "google"
	}

	func getAccessToken(_ username: String, password: String, statusUpdate: ((LoginSteps)->())? ) -> StringResult {
		return .Failure(PokemapError.unknownError)
	}
}
