//
//  Pokedex.swift
//  Pokegear GO
//
//  Created by Justin Oroz on 8/6/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation

class Pokedex {
	private let data: [String: AnyObject]
	let types: [String]
	let moves: [[String:AnyObject]]
	let pokemon: [[String:AnyObject]]
	let defenseMatrix: [[Float]]
	let attackMatrix: [[Float]]
	let starDust: [Int]
	let candy: [Int]
	let expReq: [Int]
	let cpM: [Double]


	init?() {
		if let path = Bundle.main.path(forResource: "Pokedex", ofType: "plist"),
			let naturalData  = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
			data = naturalData
			guard data["types"] is [String],
				data["moves"] is [[String:AnyObject]],
				data["pokemon"] is [[String:AnyObject]],
				data["defenseMatrix"] is [[Float]],
				data["attackMatrix"] is [[Float]] else {
					return nil
			}

			//swiftlint:disable force_cast
			types = data["types"] as! [String]
			moves = data["moves"] as! [[String:AnyObject]]
			pokemon = data["pokemon"] as! [[String:AnyObject]]
			defenseMatrix = data["defenseMatrix"] as! [[Float]]
			attackMatrix = data["attackMatrix"] as! [[Float]]
			starDust = data["stardust"] as! [Int]
			candy = data["candy"] as! [Int]
			expReq = data["expReq"] as! [Int]
			cpM = data["CpM"] as! [Double]
			//swiftlint:enable force_cast

		} else {
			return nil
		}
	}
}
