//
//  pokemon.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation

class Pokemon {
    
    private var info: [String: AnyObject]
    
    init(info: [String: String]) {
        self.info = info
    }
    
    func id() -> String {
        return info["pokemon_id"] as! String
    }
    
    func location() -> [String: Float] {
        return [
            "latitude": info["latitude"] as! Float,
            "longitude": info["longitude"] as! Float
            ]
    }
    
    func name() -> String {
        return info["pokemon_name"] as! String
    }
    
    func expires() -> Float {
        return info["expires"] as! Float
    }
    
    func expiresIn() -> String {
        // TODO: use NSTimer for countdown
        return ""
        
        
    }
    
    func description() -> String {
        return "\(self.name()) [\(id())] at (\(self.location()["latitude"]), \(self.location()["longitude"])), \(expiresIn()) seconds remaining"
    }
}