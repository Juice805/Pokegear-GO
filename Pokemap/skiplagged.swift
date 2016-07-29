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
    static let SKIPLAGGED_API = "http://skiplagged.com/api/pokemon.php"
    static let GENERAL_API = "https://pgorelease.nianticlabs.com/plfe/rpc"
    private (set) var SPECIFIC_API: String?
    private (set) var PROFILE: [String: AnyObject]?
    private (set) var PROFILE_RAW: String?
    
    //MARK: - LOGIN
    
    private (set) var ACCESS_TOKEN: String?
    private (set) var AUTH_PROVIDER: String?
    private (set) var USERNAME: String?
    private (set) var PASSWORD: String?
    
    var skiplaggedSession:Manager
    var nianticSession: Manager
    
    
    init() {
        nianticSession = getRequestsSession("Niantic App")
        skiplaggedSession = getRequestsSession("pokemongo-python")
    }
    
    //TODO: Google Login
    
    func loginWithPTC(_ username: String, password: String, completion: (boolResult) -> ()){
        print("[\(shortTime())] Login Started")
        
        let ptcAuth = PokemonTrainerClub()
        
        let provider = PokemonTrainerClub.getAuthProvider()
        
        ptcAuth.getAccessToken(username, password: password) {
            (tokenResult) in
            
            switch (tokenResult) {
            case .Success(let token):
                if let token = self.updateLogin(provider, token: token, username: username, password: password) {
                    printTimestamped("Access Token Received: \(token)")
                    completion(.Success())
                } else {
                    printTimestamped("Login Failed: No token")
                    // TODO: Make proper error
                    completion(.Failure(NSError.errorWithCode(12, failureReason: "No token")))
                    return
                }
            case .Failure(let error):
                completion(.Failure(NSError.errorWithCode(12, failureReason: "Bad token response")))
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
    
    
    func refreshLogin(_ completion: (boolResult) -> ()){
        if !isLoggedOn() {
            printTimestamped("ERROR: Requires an existing login")
            return
        } else {
            self.SPECIFIC_API = nil
            self.PROFILE = nil
            self.PROFILE_RAW = nil
            
            if self.AUTH_PROVIDER == "ptc" {
                printTimestamped("Refreshing Login")
                self.loginWithPTC(self.USERNAME!, password: self.PASSWORD!, completion: completion)
            } else  if self.AUTH_PROVIDER == "google" {
                //TODO: google login
            }
        }
    }
    
    // MARK: - Calls
    func call(_ endpoint: String, data: AnyObject, completion:(anyResult: anyResult) -> ()) {
        var session: Manager
        let isSkiplaggedSession = endpoint.contains("skiplagged")
        
        printTimestamped("JUICE- Calling " + endpoint)
        
        if isSkiplaggedSession {
            session = self.skiplaggedSession
        } else {
            session = self.nianticSession
        }
        
        if isSkiplaggedSession {
            guard let dictionaryObject = data as? [String : AnyObject] else {
                completion(anyResult: .Failure(PokemapError.invalidJSON.error))
                return
            }
            
            session.request(.POST, endpoint, parameters: dictionaryObject, encoding: .url, headers: nil).responseJSON() {
                (response) in
                
                switch response.result {
                case .failure(let error):
                    printTimestamped(error.debugDescription)
                    self.call(endpoint, data: data) { (anyResult) in
                        completion(anyResult: anyResult)
                    }
                    return
                case .success(let data):
                    completion(anyResult: .Success(data))
                    return
                    
                }
            }
        } else {
            session.request(.POST, endpoint, parameters: [:], encoding: .custom({
                (convertible, params) in
                var mutableRequest = convertible.urlRequest as URLRequest
                
                // decode
                guard let stringData = data as? String
                    else {
                        self.call(endpoint, data: data) { (anyResult) in
                            completion(anyResult: anyResult)
                        }
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
                    self.call(endpoint, data: data) { (anyResult) in
                        completion(anyResult: anyResult)
                    }
                    return
                case .success(let string):
                    
                    // encode base64
                    let encodedString = string.base64EncodedString()
                    
                    completion(anyResult: .Success(encodedString))
                    return
                    
                }
            }
            
            
        }
    }
    
    
    func getSpecificAPIEndpoint(_ completion: (specificAPIEndpointResult: stringResult) -> ()) {
        printTimestamped("Getting Specific API Endpoint")
        
        if !isLoggedOn() {
            completion(specificAPIEndpointResult: .Failure(PokemapError.notLoggedIn.error))
            return
        }
        
        let accessDict = [
            "access_token" : self.ACCESS_TOKEN!,
            "auth_provider": self.AUTH_PROVIDER!
        ]
        
        call(Skiplagged.SKIPLAGGED_API, data: accessDict) { (anyResult) in
            switch anyResult {
            case .Failure(let error):
                completion(specificAPIEndpointResult: .Failure(error))
                return
            case .Success(let data):
                guard let dict = data as? [String: AnyObject],
                JSON(dict).error == nil,
                let pdata = JSON(dict)["pdata"].string
                else {
                    completion(specificAPIEndpointResult: .Failure(PokemapError.invalidJSON.error))
                    return
                }
                
                self.call(Skiplagged.GENERAL_API, data: pdata) { (anyResult) in
                    switch anyResult {
                    case .Failure(let error):
                        completion(specificAPIEndpointResult: .Failure(error))
                        return
                    case .Success(let data):
                        guard let pdata = data as? String else {
                            completion(specificAPIEndpointResult: .Failure(PokemapError.pDataAPI.error))
                            return
                        }
                        
                        
                        // TODO:
                        printTimestamped("JUICE- SUCCESS: "+pdata)
                        
                        let endpointPayload = [
                            "access_token": self.ACCESS_TOKEN!,
                            "auth_provider": self.AUTH_PROVIDER!,
                            "pdata": pdata
                        ]
                        
                        self.call(Skiplagged.SKIPLAGGED_API, data: endpointPayload) { (anyResult) in
                            switch anyResult {
                            case .Failure(let error):
                                completion(specificAPIEndpointResult: .Failure(error))
                                return
                            case .Success(let response):
                                guard let json = response as? [String: AnyObject],
                                let specificAPI = json["api_endpoint"] as? String
                                    else {
                                        completion(specificAPIEndpointResult: .Failure(PokemapError.specificAPIEndpoint.error))
                                        return
                                }
                                
                                self.SPECIFIC_API = specificAPI
                                
                                completion(specificAPIEndpointResult: .Success(specificAPI))
                                return
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func getProfile(_ completion:(profileResult: jsonResult) -> ()) {
        printTimestamped("Getting Profile")
        
        if SPECIFIC_API == nil {
            printTimestamped("No specific API Endpoint. Getting...")
            getSpecificAPIEndpoint() { (specificAPIEndpointResult) in
                switch specificAPIEndpointResult {
                case .Failure(let error):
                    self.getProfile(){ (profileResult) in
                        completion(profileResult: profileResult)
                    }
                    printTimestamped(error.debugDescription)
                    return
                case .Success( _):
                    printTimestamped("Success")
                    self.getProfile { (result) in
                        completion(profileResult: result)
                    }
                    return
                }
            }
            return
        }
    
        let apiPayload = [
            "access_token": self.ACCESS_TOKEN!,
            "auth_provider": self.AUTH_PROVIDER!,
            "api_endpoint": self.SPECIFIC_API!
        ]
        
        self.call(Skiplagged.SKIPLAGGED_API, data: apiPayload) { (anyResult) in
            switch anyResult {
            case .Failure(let error):
                completion(profileResult: .Failure(error))
                printTimestamped("ERROR: " + error.debugDescription)
                return
            case .Success(let data):
                guard let dict = data as? [String: AnyObject],
                    let pdata = dict["pdata"]
                    else {
                        completion(profileResult: .Failure(PokemapError.expectedJSONKey.error))
                        printTimestamped("ERROR: No pdata found")
                        return
                }
                
                
                self.call(self.SPECIFIC_API!, data: pdata) { (anyResult) in
                    switch anyResult {
                    case .Failure(let error):
                        completion(profileResult: .Failure(error))
                        printTimestamped("ERROR: " + error.debugDescription)
                        return
                    case .Success(let data):
                        guard let pdata = data as? String else {
                            completion(profileResult: .Failure(PokemapError.pDataAPI.error))
                            return
                        }
                        
                        
                        self.PROFILE_RAW = pdata
                        
                        let profilePayload = [
                            "access_token": self.ACCESS_TOKEN!,
                            "auth_provider": self.AUTH_PROVIDER!,
                            "api_endpoint": self.SPECIFIC_API!,
                            "pdata" : self.PROFILE_RAW!
                        ]
                        
                        
                        self.call(Skiplagged.SKIPLAGGED_API, data: profilePayload) { (anyResult) in
                            switch anyResult {
                            case .Failure(let error):
                                completion(profileResult: .Failure(error))
                                return
                            case .Success(let response):
                                guard let profile = response as? [String: AnyObject],
                                profile["username"] != nil
                                    else {
                                        completion(profileResult: .Failure(PokemapError.noProfileData.error))
                                        return
                                }
                                
                                
                                self.PROFILE = profile
                                
                                completion(profileResult: .Success(profile))
                                return
                            }
                        }
                    }
                }
            }
        }
    }
    
    func findPokemon(bounds: ((Double, Double),(Double, Double)), step_size: Double = 0.002, completion: ([Pokemon]) -> ()) {
        // bottom Left, topRight
        printTimestamped("Finding Pokemon")
        
        if PROFILE_RAW == nil {
            printTimestamped("No profile. Getting...")
            getProfile() { (profileResult) in
                switch profileResult {
                case .Failure(let error):
                    self.findPokemon(bounds: bounds, step_size: step_size) { pokemon in
                        completion(pokemon)
                    }
                    printTimestamped(error.debugDescription)
                    return
                case .Success( _):
                    printTimestamped("Success")
                    self.findPokemon(bounds: bounds, step_size: step_size) { pokemon in
                        completion(pokemon)
                    }
                    return
                }
            }
            return
        }
        
        let lowerLeft = ["lat": bounds.0.0,
                         "long": bounds.0.1
        ]
        
        let upperRight = ["lat": bounds.1.0,
                          "long": bounds.1.1
        ]
        
        let payload: [String: AnyObject] = [
            "access_token": self.ACCESS_TOKEN!,
            "auth_provider": self.AUTH_PROVIDER!,
            "profile": self.PROFILE_RAW!,
            "bounds": "\(lowerLeft["lat"]!), \(lowerLeft["long"]!), \(upperRight["lat"]!), \(upperRight["long"]!)",
            "step_size": step_size
        ]
        
        
        self.call(Skiplagged.SKIPLAGGED_API, data: payload) { (anyResult) in
            switch anyResult {
            case .Failure(let error):
                printTimestamped("ERROR: " + error.debugDescription)
                return
            case .Success(let result):
                
                guard let dictResults = result as? [String: AnyObject],
                let requests = dictResults["requests"] as? [[String:String]]
                else {
                    printTimestamped("ERROR: " + "Response does not contain Pokemon requests")
                    return
                }
                
                printTimestamped("Requests: \(requests.count)")
                
                
                
                    scan: for request in requests {
                        
                        self.currentReq = self.currentReq.background() {
                            
                            printTimestamped("Moving player")
                            
                            self.call(self.SPECIFIC_API!, data: request["pdata"]!) { (anyResult) in
                                switch anyResult {
                                case .Failure(let error):
                                    
                                    //TODO: handle errors
                                    printTimestamped("ERROR: " + error.debugDescription)
                                    
                                    
                                    break
                                case .Success(let pokeData):
                                    
                                    self.call(Skiplagged.SKIPLAGGED_API, data: ["pdata": pokeData!]) { (anyResult) in
                                        switch anyResult {
                                        case .Failure(let error):
                                            
                                            //TODO: handle errors
                                            printTimestamped("ERROR: " + error.debugDescription)
                                            
                                            break
                                        case .Success(let response):
                                            
                                            print(response!.debugDescription)
                                            
                                            
                                            guard let respDict = response as? [String: AnyObject],
                                                let pokemons = respDict["pokemons"] as? [[String: AnyObject]] else {
                                                    
                                                    //TODO: Handle Error
                                                    printTimestamped("Couldn't decode pokemon data")
                                                    return
                                            }
                                            
                                            
                                            printTimestamped("Found \(respDict["pokemons"]!.count!) Pokemon")
                                            
                                            var foundPokemon: [Pokemon] = []
                                            
                                            for pokemon in pokemons {
                                                let poke = pokemon["pokemon_name"] as! String
                                                printTimestamped("Found " + poke)
                                                
                                                foundPokemon.append(Pokemon(info: pokemon))
                                                
                                            }
                                            
                                            completion(foundPokemon)
                                            return
                                        }
                                    }
                                    return
                                }
                            }
                            Thread.sleep(forTimeInterval: 0.1)
                        }
                    }
                
                
                return
            }
        }
        
    }
    
    var currentReq = Async.background() {}
    
    func cancelSearch(){
        self.currentReq.cancel()

        Async.background{
            self.nianticSession.session.getAllTasks { (tasks) in
                tasks.forEach { $0.cancel() }
            }
            self.skiplaggedSession.session.getAllTasks { (tasks) in
                tasks.forEach { $0.cancel() }
            }
        }
    }
    
}






