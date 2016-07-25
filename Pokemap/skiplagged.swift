//
//  skiplagged.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Async

class Skiplagged {
    private static let SKIPLAGGED_API = "http://skiplagged.com/api/pokemon.php"
    private static let GENERAL_API = "https://pgorelease.nianticlabs.com/plfe/rpc"
    private (set) var SPECIFIC_API: String?
    private (set) var PROFILE: String?
    private (set) var PROFILE_RAW: String?
    
    //MARK: - LOGIN
    
    private (set) var ACCESS_TOKEN: String?
    private (set) var AUTH_PROVIDER: String?
    private (set) var USERNAME: String?
    private (set) var PASSWORD: String?
    
    //TODO: Google Login
    
    func loginWithPTC(_ username: String, password: String, completion: () -> ()){
        print("[\(shortTime())] Login Started")
        
        let ptcAuth = PokemonTrainerClub()
        
        let provider = PokemonTrainerClub.getAuthProvider()
        
        ptcAuth.getAccessToken(username, password: password) {
            (tokenResult) in
            
            switch (tokenResult) {
            case .Success(let token):
                if let token = self.updateLogin(provider, token: token, username: username, password: password) {
                    printTimestamped("Access Token Received: \(token)")
                    completion()
                } else {
                    printTimestamped("Login Failed: No token")
                    return
                }
            case .Failure(let error):
                printTimestamped("Login Failed: " + error.debugDescription)
                return
            }
        }
    }
    
    func updateLogin(_ provider: String, token: String?, username: String, password: String) -> (String)? {
        if token != nil {
            self.AUTH_PROVIDER = provider
            self.ACCESS_TOKEN = token!
            self.USERNAME = username
            self.PASSWORD = password
            
            return self.ACCESS_TOKEN!
        } else {
            return nil
        }
        
    }
    
    func isLoggedOn() -> Bool {
        if self.ACCESS_TOKEN != nil { return true }
        else { return false}
    }
    
    
    func refreshLogin(_ completion: () -> ()){
        if !isLoggedOn() {
            printTimestamped("ERROR: Requires an existing login")
            return
        } else {
            self.SPECIFIC_API = ""
            self.PROFILE = ""
            self.PROFILE_RAW = ""
            
            if self.AUTH_PROVIDER == "ptc" {
                printTimestamped("Refreshing Login")
                self.loginWithPTC(self.USERNAME!, password: self.PASSWORD!, completion: completion)
            } else  if self.AUTH_PROVIDER == "google" {
                //TODO: google login
            }
        }
    }
    
    // MARK: - Calls
    
    func call(_ endpoint: String, data: JSON, completion: (jsonResult: jsonResult) -> ()) {
        let isSkiplaggedAPI = endpoint.contains("skiplagged")
        
        var session: Manager
        
        
        if isSkiplaggedAPI {
            session = setRequestsSession("pokemongo-python")
        } else {
            session = setRequestsSession("Niantic App")
        }
        
        print(session.session.configuration.httpAdditionalHeaders)
        
        
        Async.background {
            while true {
                
                if isSkiplaggedAPI {
                    session.request(.POST,
                                      endpoint,
                                      parameters: data.dictionaryObject,
                                      encoding: .json,
                                      headers: nil)
                        .validate().responseJSON() {
                            (response) in
                            
                            switch response.result {
                            case .success(let data):
                                let json = JSON(data as! [String: AnyObject])
                                if let error = json.error {
                                    completion(jsonResult: .Failure(error))
                                    return
                                } else {
                                    completion(jsonResult: .Success(json))
                                    return
                                }
                            case .failure(let error):
                                printTimestamped("Skiplagged API request failed with error: \(error.debugDescription)")
                                
                                if let data = response.data {
                                    printTimestamped("Response: \(String(data: data, encoding: String.Encoding.utf8) )")
                                }
                                completion(jsonResult: .Failure(error))
                                return
                            }
                    }
                    
                } else {
                    session.request(.POST,
                                      endpoint,
                                      parameters: data.dictionaryObject,
                                      encoding: .url,
                                      headers: nil)
                        .validate().responseJSON() { (response) in
                            switch response.result {
                            case .success(let data):
                                printTimestamped("")
                                completion(jsonResult: .Success(JSON(data)))
                                
                            case .failure(let error):
                                printTimestamped("Niantic request failed with error: \(error.debugDescription)")
                                
                                if let data = response.data {
                                    printTimestamped("Response: \(String(data: data, encoding: String.Encoding.utf8)! )")
                                }
                                completion(jsonResult: .Failure(error))
                                return
                            }
                            
                            
                        }
                }
                
                sleep(1)
                
            }
        }
        
        
    }
    
    func getSpecificAPIEndpoint(_ completion: (specificAPIEndpointResult: stringResult) -> ()) {
        printTimestamped("called get_specific_api_endpoint")
        if !isLoggedOn() {
            printTimestamped(PokemapError.pDataAPI.description);
            completion(specificAPIEndpointResult: .Failure(NSError.errorWithCode(1, failureReason: "Must be logged in")))
            return
        }
        
        // request 1
        self.call(Skiplagged.SKIPLAGGED_API,
                  data: JSON(["access_token": self.ACCESS_TOKEN!,
                              "auth_provider": self.AUTH_PROVIDER!])) {
                                (jsonResult) in
                                
                                switch jsonResult {
                                case .Failure(let error):
                                    printTimestamped(error.description)
                                    completion(specificAPIEndpointResult: .Failure(error))
                                    return
                                case .Success(let json):
                                    guard let dict = json?.dictionaryObject,
                                        let pdata1 = dict["pdata"]
                                        else {
                                            let error = PokemapError.expectedJSONKey.error
                                            printTimestamped((json?.description)!)
                                            completion(specificAPIEndpointResult: .Failure(error))
                                            return
                                    }
                                    
                                    
                                    // request 2
                                    self.call(Skiplagged.GENERAL_API,
                                              data: JSON(pdata1)) {
                                                (jsonResult) in
                                                
                                                switch jsonResult {
                                                case .Failure(let error):
                                                    printTimestamped("Failed to get PData")
                                                    completion(specificAPIEndpointResult: .Failure(error))
                                                    return
                                                case .Success(let json):
                                                    guard let pdata = json?.dictionaryObject else {
                                                        let error = PokemapError.invalidJSON.error
                                                        completion(specificAPIEndpointResult: .Failure(error))
                                                        return
                                                    }
                                                    
                                                    // request 3
                                                    self.call(Skiplagged.SKIPLAGGED_API,
                                                              data: JSON(["access_token": self.ACCESS_TOKEN!,
                                                                          "auth_provider": self.AUTH_PROVIDER!,
                                                                          "pdata": pdata])) {
                                                                            (jsonResult) in
                                                                            
                                                                            switch jsonResult {
                                                                            case .Failure(let error):
                                                                                completion(specificAPIEndpointResult: .Failure(error))
                                                                                break
                                                                            case .Success(let json):
                                                                                guard let apiEndpoint = json?["api_endpoint"] as? String
                                                                                    else {
                                                                                        let error = PokemapError.specificAPIEndpoint.error
                                                                                        completion(specificAPIEndpointResult: .Failure(error));
                                                                                        return
                                                                                }
                                                                                self.SPECIFIC_API = apiEndpoint
                                                                                completion(specificAPIEndpointResult: .Success(self.SPECIFIC_API))
                                                                                break
                                                                            }
                                                }
                                        }
                                    }
                                }
        }
    }
    
    
    func getProfile(_ completetion:()->()) {
        //
        
        if self.SPECIFIC_API == nil {
            getSpecificAPIEndpoint({ (specificAPIEndpoint) in
                //TODO: get it
            })
        } else {
            
        }
        
        
    }
    
}






