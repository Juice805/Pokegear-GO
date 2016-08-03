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
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
