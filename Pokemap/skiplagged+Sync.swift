//
//  skiplagged+Sync.swift
//  Pokegear GO
//
//  Created by Justin Oroz on 7/30/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import Alamofire
import Async

extension Skiplagged {
	func loginWithPTC(_ username: String, password: String) -> BoolResult {
		print("[\(shortTime())] Login Started")

		let ptcAuth = PokemonTrainerClub()
		let provider = PokemonTrainerClub.getAuthProvider()
		var result: BoolResult = .Failure(NSError())
		let queue = AsyncGroup()


		queue.enter()
		ptcAuth.getAccessToken(username, password: password) {
			(tokenResult) in

			switch tokenResult {
			case .Success(let token):
				if let token = self.updateLogin(provider, token: token, username: username, password: password) {
					printTimestamped("Access Token Received: \(token)")
					result = .Success()
					queue.leave()
					return
				} else {
					printTimestamped("Login Failed: No token")
					// TODO: Make proper error
					result = .Failure(NSError.errorWithCode(12, failureReason: "No token"))
					queue.leave()
					return
				}
			case .Failure(let error):
				result = .Failure(NSError.errorWithCode(12, failureReason: "Bad token response"))
				printTimestamped("Login Failed: " + error.debugDescription)
				queue.leave()
				return
			}
		}

		queue.wait()
		return result
	}

	//TODO: Google Login

	func refreshLogin() -> BoolResult {
		if !isLoggedOn() {
			printTimestamped("ERROR: Requires an existing login")
			return .Failure(PokemapError.notLoggedIn.error)
		} else {
			self.API_SPECIFIC = nil
			self.PROFILE = nil
			self.PROFILE_RAW = nil

			printTimestamped("Refreshing Login")
			if self.authProvider == "ptc" {
				return self.loginWithPTC(self.username!, password: self.password!)
			} else  if self.authProvider == "google" {
				//TODO: google login
				return .Failure(NSError.errorWithCode(100, failureReason: "Unimplemented"))
			}
		}
		return .Failure(NSError.errorWithCode(99, failureReason: "Unknown Error"))
	}


	// MARK: - Calls
	func call(_ endpoint: String, data: AnyObject) -> AnyResult {
		var session: Manager
		let isSkiplaggedSession = endpoint.contains("skiplagged")
		let queue = AsyncGroup()
		var result: AnyResult = .Failure(NSError.errorWithCode(99, failureReason: "Unknown Error"))

		printTimestamped("JUICE- Calling " + endpoint)

		if isSkiplaggedSession {
			session = self.skiplaggedSession
		} else {
			session = self.nianticSession
		}

		if isSkiplaggedSession {
			guard let dictionaryObject = data as? [String : AnyObject] else {
				return .Failure(PokemapError.invalidJSON.error)
			}

			queue.enter()
			session.request(.POST, endpoint,
			                parameters: dictionaryObject,
			                encoding: .url,
			                headers: nil)
				.responseJSON() {
					(response) in

					switch response.result {
					case .failure(let error):
						printTimestamped(error.debugDescription)
						result = .Failure(error)
						queue.leave()
						return
					case .success(let data):
						result = .Success(data)
						queue.leave()
						return
					}
			}

			queue.wait()
			return result
		} else {
			queue.enter()
			session.request(.POST, endpoint, parameters: [:], encoding: .custom({
				(convertible, params) in
				var mutableRequest = convertible.urlRequest as URLRequest

				// decode
				guard let stringData = data as? String
					else {
						result = .Failure(PokemapError.pDataAPI.error)
						printTimestamped("ERROR: " + PokemapError.pDataAPI.description)
						return (mutableRequest, PokemapError.pDataAPI.error)
				}

				mutableRequest.httpBody = Data(base64Encoded: stringData)

				return (mutableRequest, nil)
			}), headers: nil).responseData() {
				(response) in

				switch response.result {
				case .failure(let error):

					printTimestamped(error.debugDescription)

					result = .Failure(error)
					queue.leave()
					return
				case .success(let string):

					// encode base64
					let encodedString = string.base64EncodedString()

					result = .Success(encodedString)
					queue.leave()
					return

				}
			}
		}

		queue.wait()
		return result
	}

	func getSpecificAPIEndpoint() -> StringResult {
		printTimestamped("Getting Specific API Endpoint")

		if !isLoggedOn() {
			return .Failure(PokemapError.notLoggedIn.error)
		}

		let accessDict = [
			"access_token" : self.accessToken!,
			"auth_provider": self.authProvider!
		]

		let queue = AsyncGroup()
		var stepResult: AnyResult = .Failure(PokemapError.unknownError.error)

		// First Call
		stepResult = call(Skiplagged.API_SKIPLAGGED, data: accessDict)

		var pdata: String = ""
		switch stepResult {
		case .Failure(let error):
			return .Failure(error)
		case .Success(let data):
			guard let dict = data as? [String: AnyObject],
				let extractedPData = dict["pdata"] as? String
				else {
					return .Failure(PokemapError.invalidJSON.error)
			}

			pdata = extractedPData
		}



		// Second Call
		stepResult =  self.call(Skiplagged.API_GENERAL, data: pdata)

		var endpointPayload = [
			"access_token": self.accessToken!,
			"auth_provider": self.authProvider!
		]

		switch stepResult {
		case .Failure(let error):
			return .Failure(error)
		case .Success(let data):
			guard let pdata = data as? String else {
				return .Failure(PokemapError.pDataAPI.error)
			}

			endpointPayload["pdata"] = pdata
		}

		// Call 3
		stepResult =  self.call(Skiplagged.API_SKIPLAGGED, data: endpointPayload)

		queue.wait()
		switch stepResult {
		case .Failure(let error):
			return .Failure(error)
		case .Success(let response):
			guard let json = response as? [String: AnyObject],
				let specificAPI = json["api_endpoint"] as? String
				else {
					return .Failure(PokemapError.specificAPIEndpoint.error)
			}

			self.API_SPECIFIC = specificAPI

			return .Success(specificAPI)
		}
	}

	func getProfile() -> JSONResult {
		printTimestamped("Getting Profile")

		if API_SPECIFIC == nil {
			printTimestamped("No specific API Endpoint. Getting...")

			switch getSpecificAPIEndpoint() {
			case .Failure(let error):
				// TODO: Retry
				return .Failure(error)
			case .Success( _):
				printTimestamped("Retrieved specific API Endpoint. Continueing...")
				break
			}

		}

		let apiPayload = [
			"access_token": self.accessToken!,
			"auth_provider": self.authProvider!,
			"api_endpoint": self.API_SPECIFIC!
		]


		var stepResult = self.call(Skiplagged.API_SKIPLAGGED, data: apiPayload)

		var pdata: String

		switch stepResult {
		case .Failure(let error):
			return .Failure(error)
		case .Success(let data):
			guard let dict = data as? [String: AnyObject],
				let result = dict["pdata"] as? String
				else {
					return .Failure(PokemapError.expectedJSONKey.error)
			}

			pdata = result
		}

		stepResult = self.call(self.API_SPECIFIC!, data: pdata)


		switch stepResult {
		case .Failure(let error):
			return .Failure(error)
		case .Success(let data):
			guard let result = data as? String else {
				return .Failure(PokemapError.unknownError.error)
			}

			pdata = result
		}



		self.PROFILE_RAW = pdata

		let profilePayload = [
			"access_token": self.accessToken!,
			"auth_provider": self.authProvider!,
			"api_endpoint": self.API_SPECIFIC!,
			"pdata" : self.PROFILE_RAW!
		]


		stepResult = self.call(Skiplagged.API_SKIPLAGGED, data: profilePayload)

		switch stepResult {
		case .Failure(let error):

			return .Failure(error)
		case .Success(let response):
			guard let profile = response as? [String: AnyObject],
				profile["username"] != nil
				else {
					return .Failure(PokemapError.noProfileData.error)
			}


			self.PROFILE = profile

			return .Success(profile)
		}

	}

	// swiftlint:disable:next line_length
	func findPokemon(bounds: ((Double, Double), (Double, Double)), stepSize: Double = 0.002, progress: (Double) -> (), completion: ([Pokemon]) -> ()) {
		// bottom Left, topRight

		if inhibitScan {
			printTimestamped("Scan inhibited. Cancelled")
			inhibitScan = false
			return
		}

		printTimestamped("Finding Pokemon")

		if PROFILE_RAW == nil {
			printTimestamped("No profile. Getting...")

			let profileResult = getProfile()
			switch profileResult {
			case .Failure(_):
				return
			case .Success( _):
				printTimestamped("Success")
			}
		}

		let lowerLeft = ["lat": bounds.0.0,
		                 "long": bounds.0.1
		]

		let upperRight = ["lat": bounds.1.0,
		                  "long": bounds.1.1
		]

		let payload: [String: AnyObject] = [
			"access_token": self.accessToken!,
			"auth_provider": self.authProvider!,
			"profile": self.PROFILE_RAW!,
			"bounds": "\(lowerLeft["lat"]!), \(lowerLeft["long"]!), \(upperRight["lat"]!), \(upperRight["long"]!)",
			"step_size": stepSize
		]


		let locationResult = self.call(Skiplagged.API_SKIPLAGGED, data: payload)

		switch locationResult {
		case .Failure(_):
			return
		case .Success(let result):

			guard let dictResults = result as? [String: AnyObject],
				let requests = dictResults["requests"] as? [[String:String]]
				else {
					printTimestamped("ERROR: " + "Response does not contain Pokemon requests")
					return
			}

			printTimestamped("Requests: \(requests.count)")
			var requestNumber = 0

			scan: for request in requests {
				requestNumber += 1
				progress(Double(requestNumber) / Double(requests.count))

				if inhibitScan {
					inhibitScan = false
					return
				}

				printTimestamped("Moving player")

				let requestsAcquisition = self.call(self.API_SPECIFIC!, data: request["pdata"]!)

				switch requestsAcquisition {
				case .Failure(let error):

					//TODO: handle errors
					printTimestamped("ERROR: " + error.debugDescription)

					break
				case .Success(let pokeData):


					var pokeDataRecieved = false

					rateLimitCheck: while !pokeDataRecieved {
						let scan = self.call(Skiplagged.API_SKIPLAGGED, data: ["pdata": pokeData!])

						switch scan {
						case .Failure(let error):

							//TODO: handle errors
							printTimestamped("ERROR: " + error.debugDescription)


							return
						case .Success(let response):

							print(response!.debugDescription)



							guard let respDict = response as? [String: AnyObject]
								 else {
									//TODO: Handle Error
									printTimestamped("Couldn't decode response")
									return
							}

							if let error = respDict["error"] as? String {
								printTimestamped("Skiplagged: " + error)
								Thread.sleep(forTimeInterval: 1.0)
								continue rateLimitCheck
							}

							guard let pokemons = respDict["pokemons"] as? [[String: AnyObject]]
							else {
								printTimestamped("No pokemon data")
								return
							}

							pokeDataRecieved = true

							printTimestamped("Found \(pokemons.count) Pokemon")
							var foundPokemon: [Pokemon] = []
							for pokemon in pokemons {
								if let poke = pokemon["pokemon_name"] as? String {
									printTimestamped("Found " + poke)
									foundPokemon.append(Pokemon(info: pokemon)!)
								} else {
									//TODO: Handle error
								}
							}
							completion(foundPokemon)
							Thread.sleep(forTimeInterval: 0.7)
						}
					}




					}


			}
		}
	}

}
