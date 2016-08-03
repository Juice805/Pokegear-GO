//
//  ptc.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import Alamofire


class PokemonTrainerClub: Auth {

	// swiftlint:disable:next line_length
    static let LOGIN_URL = "https://sso.pokemon.com/sso/login?service=https%3A%2F%2Fsso.pokemon.com%2Fsso%2Foauth2.0%2FcallbackAuthorize"
    static let LOGIN_OAUTH = "https://sso.pokemon.com/sso/oauth2.0/accessToken"
    static let PTC_CLIENT_SECRET = "w8ScCUXJQc6kXKw8FiOhd8Fixzht18Dq3PEVkUCP5ZPxtgyWsbTvWHFLm2wNY0JR"

    static func getAuthProvider() -> String {
        return "ptc"
    }

	func getAccessToken(_ username: String, password: String, statusUpdate: ((LoginSteps)->())? ) -> StringResult {
        // Code modified from user scotbond: github.com/scotbond/PokemonGoSwiftAPI
		let loginURL = URL(string: PokemonTrainerClub.LOGIN_URL)

		// MARK: - Initial Request
		let initialResponse = syncJSONRequest(method: .GET, URLString: loginURL!, encoding: .url)


		switch initialResponse.result {
		case .failure(let error):
			printTimestamped("Initial request failed with error: \(error.debugDescription)")

			// probably PTC down
			return .Failure(error)

		case .success(let data):
			guard let json = data as? [String: AnyObject],
				let lt = json["lt"] as? String,
				let execution = json["execution"] as? String
				else {
					let error = NSError()
					//TODO: Actual error
					return .Failure(error)
			}

			if statusUpdate != nil {
				statusUpdate!(.Connected)
			}

			let params = [
				"lt": lt,
				"execution": execution,
				"_eventId": "submit",
				"username": username,
				"password": password
			]


			//MARK: Ticket Request
			let ticketResponse = syncJSONRequest(method: .POST, URLString: loginURL!, parameters: params, encoding: .url)

			guard let serverResponse = ticketResponse.response,
				let range = serverResponse.url?.urlString.range(of: ".*ticket=",
				                                                options: .regularExpression,
				                                                range: nil, locale: nil),
				let ticket = serverResponse.url?.urlString.substring(from: range.upperBound),
				ticket != ""
				else {
					return .Failure(PokemapError.incorrectLogin.error)
			}

			if statusUpdate != nil {
				statusUpdate!(.Ticket)
			}

			let oauthURL = URL(string: PokemonTrainerClub.LOGIN_OAUTH)!

			let params2 = [
				"client_id": "mobile-app_pokemon-go",
				"redirect_uri": "https://www.nianticlabs.com/pokemongo/error",
				"client_secret": PokemonTrainerClub.PTC_CLIENT_SECRET,
				"grant_type": "refresh_token",
				"code": ticket
			]


			// MARK: - Token request

			let tokenResponse = syncStringRequest(method: .POST, URLString: oauthURL, parameters: params2, encoding: .url)


			switch tokenResponse.result {
			case .failure(let error):
				return .Failure(error)

			case .success(let tokenString):
				var range = tokenString.range(of: "access_token=")
				var token = tokenString.substring(from: range!.upperBound)

				range = token.range(of: "&expires")
				token = token.substring(to: range!.lowerBound)
				if statusUpdate != nil {
					statusUpdate!(.Token)
				}
				return .Success(token)
			}
		}

	}
}
