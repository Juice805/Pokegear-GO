//
//  PokemonTableViewCell.swift
//  Pokegear GO
//
//  Created by Justin Oroz on 8/1/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import UIKit

class PokemonTableViewCell: UITableViewCell {

	

	@IBOutlet weak var name: UILabel!
	@IBOutlet weak var pokeImage: UIImageView!
	@IBOutlet weak var selectionMarker: UIButton!

	lazy var pokemon: [String:AnyObject] = [:]

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

	func loadInfo(pokemonData: [String: AnyObject]) {
		pokemon = pokemonData
		if let name = pokemonData["Name"] as? String {
			self.name.text = name

		} else {
				self.name.text = "Error"

				return
		}
	}
}
