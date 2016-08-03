//
//  ViewController.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/20/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
	@IBOutlet weak var pokemap: MKMapView!
	@IBOutlet weak var scanButton: UIButton!
	@IBOutlet weak var progress: UIProgressView!

	var locationManager: CLLocationManager = CLLocationManager()
	lazy var client = Skiplagged()
	let maxSearchAltitude: Double = 75000
	var searchCountdown: Timer? = nil
	var firstSearchQueued = false


	override func viewDidLoad() {
		super.viewDidLoad()
		self.pokemap.delegate = self
		client.inhibitScan = true
		progress.isHidden = true
		progress.setProgress(0.0, animated: false)

		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(self.selectorCancel),
		                                       name: .UIApplicationWillResignActive,
		                                       object: nil)

		while CLLocationManager.authorizationStatus() ==  .notDetermined {
			// TODO: Alert User to grant location access
			locationManager.requestAlwaysAuthorization()
		}

		if CLLocationManager.authorizationStatus() != .authorizedAlways {
			authorizationAlert(controller: self, settings: {
				//
				}, cancel: {
					//
			})
		} else {
			gotoCurrentLocation(self)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func checkLocationAuthorization() -> CLLocationManager? {
		let LocationManager = CLLocationManager()

		switch CLLocationManager.authorizationStatus() {
		case .denied, .restricted:while CLLocationManager.authorizationStatus() == .notDetermined {
			return LocationManager
		}
		// User has denied access to location
		return LocationManager
		case .notDetermined:
			LocationManager.requestAlwaysAuthorization()
			print("Requesting Location Authorization")
			return nil
		default:
			// App is allowed
			print("App is authorized for location services")
			LocationManager.startUpdatingLocation()
			return LocationManager
		}
	}

	override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "loggedout" {
			client.updateLogin()
		} else if segue.identifier == "settings" {
			if let settings = segue.destination as? SettingsViewController {
				settings.client = self.client
			}
		}
	}

}


// MARK: - Skiplagged functions
extension MapViewController {

	@IBAction func forceScan() {
		if self.pokemap.camera.altitude < maxSearchAltitude && client.scanInProgress != .Manualscan {
			client.cancelScan {
				let latDelt = self.pokemap.region.span.latitudeDelta/2
				let longDelt = self.pokemap.region.span.latitudeDelta/2
				let center = self.pokemap.region.center

				let bottomLeft = (center.latitude - latDelt, center.longitude - longDelt)
				let topRight = (center.latitude + latDelt, center.longitude + longDelt)

				let topLeft = (center.latitude + latDelt, center.longitude - longDelt)
				let bottomRight = (center.latitude - latDelt, center.longitude + longDelt)

				let vector = [ CLLocationCoordinate2DMake(topLeft.0, topLeft.1),
				               CLLocationCoordinate2DMake(topRight.0, topRight.1),
				               CLLocationCoordinate2DMake(bottomRight.0, bottomRight.1),
				               CLLocationCoordinate2DMake(bottomLeft.0, bottomLeft.1),
				               ]

				let square = MKPolygon(coordinates: vector, count: 4)

				DispatchQueue.main.sync {
					// TODO: Change Icon instead
					self.scanButton.imageView?.image = UIImage(named: "7")
					self.progress.isHidden = false
					self.pokemap.add(square)

				}

				self.client.scan(of: .Manualscan, bounds: (bottomLeft, topRight), progress: {
					progress in
						DispatchQueue.main.async {
							if progress == 0 {
								self.progress.setProgress(progress, animated: false)
							} else {
								self.progress.setProgress(progress, animated: true)
							}
						}
					}, stopped: {
						error in
						// TODO: implement & Cleanup
						// if error == nil the scan was inhibited
						DispatchQueue.main.async {
							self.scanButton.imageView?.image = UIImage(named: "pokeball")
							self.progress.isHidden = true
							self.pokemap.removeOverlays(self.pokemap.overlays)
							self.progress.progress = 0.0
						}

					}, found: {
						pokemons in

						DispatchQueue.global(qos: .userInitiated).async {
							for pokemon in pokemons {
								if pokemon.isUnique(pokemons: self.pokemap.annotations) {
									DispatchQueue.main.sync {
										self.pokemap.addAnnotation(pokemon)
										if #available(iOS 10.0, *) {
											pokemon.timer = Timer(fire: pokemon.expireTime, interval: 0.0, repeats: false, block: {
												(timer) in
												self.pokemap.removeAnnotation(pokemon)
											})
											RunLoop.current.add(pokemon.timer!, forMode: .commonModes)
										} else {
											// Fallback on earlier versions
											pokemon.timer = Timer(fireAt: pokemon.expireTime,
											                      interval: 0.0,
											                      target: self,
											                      selector: #selector(self.removePokemonfromTimer),
											                      userInfo: pokemon, repeats: false)
										}
									}
								}
							}


						}
				})
			}
		} else {
			if !client.cancelling {
				client.cancelScan {
					// TODO: Change icon back
					DispatchQueue.main.async {
						self.scanButton.imageView?.image = UIImage(named: "pokeball")
						self.progress.isHidden = true
						self.pokemap.removeOverlays(self.pokemap.overlays)
					}
				}
			}
		}
	}

	func selectorCancel() {
		self.client.cancelScan()
	}


	func removePokemonfromTimer(timer: Timer) {
		DispatchQueue.main.async {
			if let pokemon = timer.userInfo as? Pokemon {
				self.pokemap.removeAnnotation(pokemon)
			}
		}
	}
}


// MARK: - Mapview functions
extension MapViewController: MKMapViewDelegate {

	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if let pokemon = annotation as? Pokemon {
			let pokeDetail = MKAnnotationView()
			pokeDetail.annotation = pokemon
			pokeDetail.isEnabled = true
			pokeDetail.image = UIImage(named: "pixel\(pokemon.dexID)")
			pokeDetail.canShowCallout = true
			pokeDetail.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
			return pokeDetail
		} else if annotation is MKUserLocation {
			return nil
		} else {
			// Handle other types of pins
		}
		return MKAnnotationView()
	}

	func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
		for view in views {
			if let pokemon = view.annotation as? Pokemon {
				view.image = UIImage(named: "\(pokemon.dexID)")!

				let newImage = UIImage(named: "pixel\(pokemon.dexID)")


				UIView.transition(with: view, duration: 2.0,
				                  options: [.beginFromCurrentState, .showHideTransitionViews],
				                  animations: {
									view.image = newImage

					},
				                  completion: nil )

				//TODO: Animate Pin drop
			} else if view.annotation is MKUserLocation {
				continue
			} else {
				//TODO: Others
				continue
			}
		}
	}

	func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {

		if self.searchCountdown != nil {
			self.searchCountdown!.invalidate()
			self.searchCountdown = nil
		}


	}

	func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

		if client.scanInProgress == .Manualscan {

		} else if mapView.userTrackingMode == .followWithHeading
			|| mapView.userTrackingMode == .follow {



		} else {
//			if #available(iOS 10.0, *) {
//				self.searchCountdown = Timer(fire: Date(timeIntervalSinceNow: 3),
//				                             interval: 0.0, repeats: false) {
//												(timer) in
//												self.client.inhibitScan = false
//												//self.searchMap(mapView)
//												DispatchQueue.main.async {
//													self.scanButton.isHidden = true
//													self.progress.setProgress(0.0, animated: false)
//													self.progress.isHidden = false
//												}
//				}
//				RunLoop.current.add(self.searchCountdown!, forMode: .commonModes)
//			} else {
//				// TODO: Timer: Fallback on earlier versions
//			}
		}
	}


	func mapView(_ mapView: MKMapView!, rendererFor overlay: MKOverlay!) -> MKOverlayRenderer! {
		if overlay is MKPolygon {
			let polygonView = MKPolygonRenderer(overlay: overlay)
			polygonView.strokeColor = #colorLiteral(red: 0.05439098924, green: 0.1344551742, blue: 0.1884709597, alpha: 1).withAlphaComponent(0.2)
			polygonView.fillColor = #colorLiteral(red: 0.4120420814, green: 0.8022739887, blue: 0.9693969488, alpha: 1).withAlphaComponent(0.05)
			polygonView.lineWidth = 1

			return polygonView
		} else {
			return nil
		}
	}

}


// MARK: - Location Functions
extension MapViewController: CLLocationManagerDelegate {

	@IBAction func gotoCurrentLocation(_ sender: AnyObject) {
		self.pokemap.setUserTrackingMode(.follow, animated: true)
	}

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if checkLocationAuthorization() != nil {
			gotoCurrentLocation(self)
		}
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("Location error: \(error.localizedDescription)")
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if self.firstSearchQueued {
			self.firstSearchQueued = false
			//searchMap(self.pokemap)
		}
	}
}

extension MapViewController: UINavigationBarDelegate {
	func position(for bar: UIBarPositioning) -> UIBarPosition {
		return .topAttached
	}
}
