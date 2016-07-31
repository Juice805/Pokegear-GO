//
//  general.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


func authorizationAlert(controller: UIViewController,settings:() -> (), cancel: () -> ()) {
	let alert = UIAlertController(title: "Location Authorization Required",
	                              message: "Please authorize Pokegear GO to view your location in Privacy Settings",
	                              preferredStyle: .alert)
	let settings = UIAlertAction(title: "Settings", style: .default, handler: {
		(_) in
		let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
		if let url = settingsURL {
			UIApplication.shared().openURL(url)
			settings()
		}

	})

	let cancel = UIAlertAction(title: "Cancel", style: .cancel) {
		_ in
		cancel()
	}

	alert.addAction(settings)
	alert.addAction(cancel)

	controller.present(alert, animated: true, completion: nil)
	return
}


// TODO: Find out what userAgent is
func getRequestsSession(_ userAgent: String? = nil) -> Manager {
    // Create the server trust policies
    let serverTrustPolicies: [String: ServerTrustPolicy] = [
        "nianticlabs.com": .disableEvaluation,
        "skiplagged.com": .disableEvaluation
    ]

    // Create custom manager
    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = Alamofire.Manager.defaultHTTPHeaders
    configuration.httpAdditionalHeaders!["User-Agent"] = userAgent

    print("JUICE- ADDITIONAL HEADERS"+configuration.httpAdditionalHeaders!.debugDescription)
    let man = Alamofire.Manager(
        configuration: configuration,
        serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
    )

    return man
}

func shortTime() -> String {
    return DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
}

func printTimestamped(_ text: String) {
    print("[" + shortTime() + "] " + text)
}

enum PokemapError: ErrorProtocol {
	case unknownError
    case emptyUsername
    case emptyPassword
    case notLoggedIn
    case pDataAPI
    case specificAPIEndpoint
    case invalidJSON
    case expectedJSONKey
    case noProfileData
	var description: String { return self.error.debugDescription }

    var error: NSError {
        switch self {
		case .unknownError:
			return NSError.errorWithCode(99, failureReason: "Unknown Error")
        case .emptyUsername:
            return NSError.errorWithCode(1, failureReason: "Username cannot be empty")
        case .emptyPassword:
            return NSError.errorWithCode(2, failureReason: "Password cannot be empty")
        case .notLoggedIn:
            return NSError.errorWithCode(0, failureReason: "Must be logged in")
        case .pDataAPI:
            return NSError.errorWithCode(11, failureReason: "Failed to get PData")
        case .specificAPIEndpoint:
            return NSError.errorWithCode(10, failureReason: "Failed to get specific API endpoint")
        case .invalidJSON:
            return NSError.errorWithCode(3, failureReason: "Invalid JSON response")
        case .expectedJSONKey:
            return NSError.errorWithCode(4, failureReason: "Expected JSON key but did not exist")
        case .noProfileData:
            return NSError.errorWithCode(12, failureReason: "No Profile data received")
        }
    }

}


enum StringResult {
    case Success(String?)
    case Failure(NSError)

	var success: Bool {
		switch self {
		case .Failure(_):
			return false
		case .Success(_):
			return true
		}
	}
}

enum JSONResult {
    case Success([String: AnyObject]?)
    case Failure(NSError)

	var success: Bool {
		switch self {
		case .Failure(_):
			return false
		case .Success(_):
			return true
		}
	}
}

enum AnyResult {
    case Success(AnyObject?)
    case Failure(NSError)

	var success: Bool {
		switch self {
		case .Failure( _):
			return false
		case .Success(_):
			return true
		}
	}
}

enum BoolResult {
    case Success()
    case Failure(NSError)

	var success: Bool {
		switch self {
		case .Failure(_):
			return false
		case .Success(_):
			return true
		}
	}
}


extension NSError {

    static func errorWithCode(_ code: Int, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: "pokegear.justinoroz.me", code: code, userInfo: userInfo)
    }

}
