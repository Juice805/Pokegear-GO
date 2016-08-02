//
//  Alamofire+Synchronous.swift
//  Pokegear GO
//
//  Created by Justin Oroz on 8/2/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import Alamofire

extension Manager {
	func syncJSONRequest(method: Alamofire.Method,
	                 // swiftlint:disable:next variable_name
	                 URLString: URLStringConvertible,
	                 parameters: [String : AnyObject]? = nil,
	                 encoding: ParameterEncoding,
	                 headers: [String : String]? = nil) -> Response<AnyObject, NSError>? {
		let queue = DispatchGroup()


		queue.enter()
		var theResponse: Response<AnyObject, NSError>? = nil
		// MARK: - Initial Request
		Alamofire.request(method, URLString, parameters: parameters, encoding: encoding, headers: headers)
			.validate().responseJSON {
				(response) in

				theResponse = response

				queue.leave()
		}

		queue.wait()

		return theResponse
	}
}
