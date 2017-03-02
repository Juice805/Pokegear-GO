//
//  pokemon.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/21/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation
import MapKit

class PokemonAnnotation: NSObject, MKAnnotation {

    let coordinate: CLLocationCoordinate2D
    private var info: [String: AnyObject]
    let dexID: Int
    let name: String
    let expireTime: Date
    var timer: Timer? = nil
    var title: String? {
        return self.name.replacingOccurrences(of: " M", with: "♂")
			.replacingOccurrences(of: " F", with: "♀") + " " + self.expiresIn()
    }

    init?(info: [String: AnyObject]) {
        self.info = info

		guard let lat = info["latitude"] as? Double,
		let long = info["longitude"] as? Double,
		let id = info["pokemon_id"] as? Int,
		let expireTimestamp = info["expires"] as? Int,
		let name = AppDelegate.pokedex.pokemon[id]["Name"] as? String
		else {
			return nil
		}

		self.name = name
		self.dexID = id
        self.coordinate = CLLocationCoordinate2D(latitude: Double(lat), longitude: Double(long))
        self.expireTime = Date(timeIntervalSince1970: TimeInterval(expireTimestamp))
    }

    func expiresIn() -> String {
        // TODO: use NSTimer for countdown
        let minute = self.expireTime.timeIntervalSinceNow / 60
        let second = self.expireTime.timeIntervalSinceNow.truncatingRemainder(dividingBy: 60)
        return String(format: "%02d:%02d", Int(minute), Int(second))
    }

    func about() -> String {
		return String(format: "%s [%d] at %f, %f. %s remaining",
		              self.name, self.dexID, self.coordinate.latitude, self.coordinate.longitude, expiresIn())
    }

    func isUnique(pokemons: [MKAnnotation]) -> Bool {
        for pokemon in pokemons {
            if let poke = pokemon as? PokemonAnnotation {

				let timeDiff = Calendar.current.dateComponents([.second], from: poke.expireTime, to: self.expireTime)

                if poke.dexID == self.dexID
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
