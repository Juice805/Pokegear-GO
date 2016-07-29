//
//  pokemon.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import MapKit

class Pokemon: NSObject, MKAnnotation {
    
    let coordinate: CLLocationCoordinate2D
    private var info: [String: AnyObject]
    let id: Int
    let name: String
    let expireTime: Date
    var timer: Timer? = nil
    var title: String? {
        return self.name.replacingOccurrences(of: " M", with: "♂").replacingOccurrences(of: " F", with: "♀") + " " + self.expiresIn()
    }
    
    init(info: [String: AnyObject]) {
        self.info = info
        
        let lat = info["latitude"] as! Double
        let long = info["longitude"] as! Double
        self.coordinate = CLLocationCoordinate2D(latitude: Double(lat), longitude: Double(long))
        
        self.id = info["pokemon_id"] as! Int
        self.name = info["pokemon_name"] as! String
        
        let expireTimestamp = info["expires"] as! Int
        self.expireTime = Date(timeIntervalSince1970: TimeInterval(expireTimestamp))
        
    }

    func expiresIn() -> String {
        // TODO: use NSTimer for countdown
        let minute = self.expireTime.timeIntervalSinceNow / 60
        let second = self.expireTime.timeIntervalSinceNow.truncatingRemainder(dividingBy: 60)
        return String(format: "%02d:%02d", Int(minute), Int(second))
    }
    
    func about() -> String {
        return "\(self.name) [\(self.id)] at (\(self.coordinate.latitude), \(self.coordinate.longitude)), \(expiresIn()) seconds remaining"
    }
    
    func isUnique(pokemons: [MKAnnotation]) -> Bool {
        for pokemon in pokemons {
            if let poke = pokemon as? Pokemon {
                
                let timeDiff = Calendar.current.components([.second], from: poke.expireTime, to: self.expireTime, options: [])
                
                if poke.id == self.id
                    && poke.coordinate.latitude == self.coordinate.latitude
                    && poke.coordinate.longitude == self.coordinate.longitude
                    && timeDiff.second! < 10 {
                    return false
                }
            }
        }
        
        return true
    }
    
    
}
