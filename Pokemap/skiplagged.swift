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
        
        ptcAuth.getAccessToken(username, password: password) { (token, error) in
            
            if token != nil && error == nil {
                if let _ = self.updateLogin(provider, token: token, username: username, password: password) {
                    printTimestamped("Access Token Received")
                    completion()
                    return
                } else {
                    printTimestamped("Login Failed: No Token Received")
                    return
                }
            } else {
                printTimestamped("Login Failed: " + error.debugDescription)
                return
            }
        }
    }
    
    func updateLogin(_ provider: String, token: String?, username: String, password: String) -> (provider: String, token: String)? {
        if token != nil {
            self.AUTH_PROVIDER = provider
            self.ACCESS_TOKEN = token!
            self.USERNAME = username
            self.PASSWORD = password
            
            return (self.AUTH_PROVIDER!, self.ACCESS_TOKEN!)
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
                self.loginWithPTC(self.USERNAME!, password: self.PASSWORD!, completion: completion)
            } else  if self.AUTH_PROVIDER == "google" {
                //TODO: google login
            }
        }
    }
    
    // MARK: - Calls
    
    func call(_ endpoint: String, data: JSON, completion: (data: [String: AnyObject]?, error: NSError?) -> ()) {
        let isSkiplaggedAPI = endpoint.contains("skiplagged")
        
        if isSkiplaggedAPI {
            setRequestsSession("pokemongo-python")
        } else {
            setRequestsSession("Niantic App")
        }
        
        while true {
            
                if isSkiplaggedAPI {
                    Alamofire.request(.POST,
                                      endpoint,
                                      parameters: data.dictionaryObject,
                                      encoding: .url,
                                      headers: nil)
                    .validate().responseJSON(completionHandler: { (response) in
                        switch response.result {
                        case .success(let data): break
                        case .failure(let error):
                            printTimestamped("Skiplagged API request failed with error: \(error.debugDescription)")
                            
                            if let data = response.data {
                                printTimestamped("Response: \(String(data: data, encoding: String.Encoding.utf8) )")
                            }
                             completion(data: nil, error: error)
                            return
                        }
                        
                        let json = JSON(data: response.data!)
                        if let error = json.error {
                            completion(data: nil, error: error)
                            return
                        } else {
                            completion(data: json.dictionaryObject, error: nil)
                        }
                    })
                } else {
                    Alamofire.request(.POST,
                        endpoint,
                        parameters: data.dictionaryObject,
                        encoding: .url,
                        headers: nil)
                        .validate().responseJSON(completionHandler: { (response) in
                            switch response.result {
                            case .success(let data): break
                            case .failure(let error):
                                printTimestamped("Skiplagged API request failed with error: \(error.debugDescription)")
                                
                                if let data = response.data {
                                    printTimestamped("Response: \(String(data: data, encoding: String.Encoding.utf8) )")
                                }
                                completion(data: nil, error: error)
                                return
                            }
                            
                            let json = JSON(data: response.data!)
                            if let error = json.error {
                                completion(data: nil, error: error)
                                return
                            } else {
                                completion(data: json.dictionaryObject, error: nil)
                            }
                        })
                }
            
        }
        
    }
    
    func getSpecificAPIEndpoint(_ completion: (specificAPIEndpoint: String?) -> ()) {
        printTimestamped("called get_specific_api_endpoint")
        if !isLoggedOn() {
            printTimestamped(PokemapErrors.pDataAPI.description); completion(specificAPIEndpoint: nil)
            return
        }
        
        // request 1
        self.call(Skiplagged.SKIPLAGGED_API,
                  data: JSON(["access_token": self.ACCESS_TOKEN!,
                    "auth_provider": self.AUTH_PROVIDER!])) {
                        (data, error) in
                        if error == nil {
                            guard let pdata1 = data!["pdata"] else {
                                printTimestamped(PokemapErrors.pDataAPI.description); completion(specificAPIEndpoint: nil); return
                            }
                            
                            // request 2
                            self.call(Skiplagged.GENERAL_API,
                                      data: JSON(pdata1))
                            { (data, error) in
                                
                                guard let pdata = data else {
                                    printTimestamped(PokemapErrors.pDataAPI.description); completion(specificAPIEndpoint: nil); return
                                }
                                
                                // request 3
                                self.call(Skiplagged.SKIPLAGGED_API,
                                          data: JSON(["access_token": self.ACCESS_TOKEN!,
                                            "auth_provider": self.AUTH_PROVIDER!,
                                            "pdata": pdata])) {
                                                (data, error) in
                                                if error == nil {
                                                    guard let apiEndpoint = data!["api_endpoint"] as? String
                                                        else {
                                                            printTimestamped(PokemapErrors.specificAPIEndpoint.description)
                                                            completion(specificAPIEndpoint: nil); return }
                                                    self.SPECIFIC_API = apiEndpoint
                                                    completion(specificAPIEndpoint: self.SPECIFIC_API)
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
        }
        
        
    }
    
}






