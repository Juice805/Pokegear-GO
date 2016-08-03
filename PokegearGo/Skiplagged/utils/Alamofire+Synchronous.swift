//
//  Alamofire+Synchronous.swift
//  Pokegear GO
//
//  Created by Justin Oroz on 8/2/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import Alamofire


func syncJSONRequest(method: Alamofire.Method,
                     // swiftlint:disable:next variable_name
	URLString: URLStringConvertible,
	parameters: [String : AnyObject]? = nil,
	encoding: ParameterEncoding,
	headers: [String : String]? = nil) -> Response<AnyObject, NSError> {
	let queue = DispatchGroup()


	queue.enter()
	var requestResponse: Response<AnyObject, NSError>? = nil
	// MARK: - Initial Request
	Alamofire.request(method, URLString, parameters: parameters, encoding: encoding, headers: headers)
		.validate().responseJSON {
			(response) in

			requestResponse = response

			queue.leave()
	}

	queue.wait()

	return requestResponse!
}

func syncStringRequest(method: Alamofire.Method,
                     // swiftlint:disable:next variable_name
	URLString: URLStringConvertible,
	parameters: [String : AnyObject]? = nil,
	encoding: ParameterEncoding,
	headers: [String : String]? = nil) -> Response<String, NSError> {
	let queue = DispatchGroup()


	queue.enter()
	var requestResponse: Response<String, NSError>? = nil
	// MARK: - Initial Request
	Alamofire.request(method, URLString, parameters: parameters, encoding: encoding, headers: headers)
		.validate().responseString {
			(response) in

			requestResponse = response

			queue.leave()
	}

	queue.wait()

	return requestResponse!
}

