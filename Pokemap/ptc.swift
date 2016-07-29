//
//  ptc.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


class PokemonTrainerClub: Auth {

	// swiftlint:disable:next line_length
    static let LOGIN_URL = "https://sso.pokemon.com/sso/login?service=https%3A%2F%2Fsso.pokemon.com%2Fsso%2Foauth2.0%2FcallbackAuthorize"
    static let LOGIN_OAUTH = "https://sso.pokemon.com/sso/oauth2.0/accessToken"
    static let PTC_CLIENT_SECRET = "w8ScCUXJQc6kXKw8FiOhd8Fixzht18Dq3PEVkUCP5ZPxtgyWsbTvWHFLm2wNY0JR"

    static func getAuthProvider() -> String {
        return "ptc"
    }

    func getAccessToken(_ username: String, password: String, completion: (tokenResult: StringResult) -> ()) {
        // Code modified from user scotbond: github.com/scotbond/PokemonGoSwiftAPI

        getInitialResponse(username, password: password) { (tokenResult) in
            completion(tokenResult: tokenResult)
        }
    }

	private func getInitialResponse(_ username: String, password: String, completion: (tokenResult: StringResult) -> ()) {
        let loginURL = URL(string: PokemonTrainerClub.LOGIN_URL)

		Alamofire.request(.GET, loginURL!, parameters: nil, encoding: .url, headers: nil)
			.validate().responseJSON {
            (response) in
            switch response.result {
            case .failure(let error):
                printTimestamped("Initial request failed with error: \(error.debugDescription)")
                if let data = response.data {
					printTimestamped("Response: \(String(data: data, encoding: String.Encoding.utf8) )")
                }
                completion(tokenResult: .Failure(error))
                return
            case .success(let data):
				guard let json = data as? [String: AnyObject],
				let lt = json["lt"] as? String,
				let execution = json["execution"] as? String
					else {
						let error = NSError()
						completion(tokenResult: .Failure(error))
						return
				}
                let params = [
                    "lt":lt,
                    "execution": execution,
                    "_eventId": "submit",
                    "username": username,
                    "password": password
                ]
                self.getTicket(params) { (tokenResult) in
                    completion(tokenResult: tokenResult)
                }
            }
        }
    }

	private func getTicket(_ params: [String: AnyObject], completion: (tokenResult: StringResult) -> ()) {
        let loginURL = URL(string: PokemonTrainerClub.LOGIN_URL)

        // Second Request
        Alamofire.request(.POST, loginURL!,
                          parameters: params,
                          encoding: .url,
                          headers: nil)
            .validate().responseJSON() {
                (response) in
                guard let actualResponse = response.response,
                    let range = actualResponse.url!.urlString.range(of: ".*ticket=",
                                                                    options: .regularExpression,
                                                                    range: nil, locale: nil)
                    else {
                        let error = NSError.errorWithCode(NSURLErrorCannotParseResponse,
                                                          failureReason: "Expected a ticket")
                        completion(tokenResult: .Failure(error))
                        return
                }

                let ticket = actualResponse.url!.urlString.substring(from: range.upperBound)
                let oauthURL = URL(string: PokemonTrainerClub.LOGIN_OAUTH)!

                let params2 = [
                    "client_id": "mobile-app_pokemon-go",
                    "redirect_uri": "https://www.nianticlabs.com/pokemongo/error",
                    "client_secret": PokemonTrainerClub.PTC_CLIENT_SECRET,
                    "grant_type": "refresh_token",
                    "code": ticket
                ]

                Alamofire.request(.POST,
                                  oauthURL,
                                  parameters: params2,
                                  encoding: .url,
                                  headers: nil)
                    .validate().responseString() { response in

                        switch response.result {
                        case .failure(let error):
                            completion(tokenResult: .Failure(error))
                        case .success(let tokenString):
                            var range = tokenString.range(of: "access_token=")
                            var token = tokenString.substring(from: range!.upperBound)
                            range = token.range(of: "&expires")
                            token = token.substring(to: range!.lowerBound)
                            completion(tokenResult: .Success(token))
                        }
                }
            }
    }
}
