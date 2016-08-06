//
//  FilterViewController.swift
//  Pokegear GO
//
//  Created by Justin Oroz on 8/1/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class FilterViewController: UIViewController {

	lazy var map: MKMapView? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
	@IBAction func dismissSelf(_ sender: AnyObject) {
		self.modalTransitionStyle = .coverVertical
		//self.popoverPresentationController?.presentedViewController.dismiss(animated: true, completion: nil)
		dismiss(animated: true, completion: nil)

	}
}

extension FilterViewController: UITableViewDelegate {

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 120
	}
}

extension FilterViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 151
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if let pokemon = tableView.dequeueReusableCell(withIdentifier: "Pokemon") as? PokemonTableViewCell {
			pokemon.pokeImage.image = UIImage(named: "\(indexPath.row + 1)")
			pokemon.name.text = "Bulbasaur"
			return pokemon
		} else {
			return UITableViewCell()
		}

	}
}
