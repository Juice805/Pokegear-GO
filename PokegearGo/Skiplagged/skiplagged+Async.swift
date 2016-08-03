//
//  skiplagged+Async.swift
//  Pokegear GO
//
//  Created by Justin Oroz on 7/30/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import Alamofire


// Asynchronous Skiplagged functions
extension Skiplagged {

	func loginWithPTC(_ username: String, password: String, statusUpdate: (LoginSteps) -> (), completion: (BoolResult) -> ()) {
		print("[\(shortTime())] Login Started")

		let ptcAuth = PokemonTrainerClub()
		let provider = PokemonTrainerClub.getAuthProvider()

		let token = ptcAuth.getAccessToken(username, password: password, statusUpdate: statusUpdate)

		switch token {
		case .Success(let token):
			self.updateLogin(provider, token: token, username: username, password: password) 
				printTimestamped("Access Token Received: \(token)")
				completion(.Success())

		case .Failure(let error):
			completion(.Failure(NSError.errorWithCode(12, failureReason: "Bad token response")))
			printTimestamped("Login Failed: " + error.debugDescription)
			return
		}
	}
}
