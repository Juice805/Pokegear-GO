//
//  ViewController.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/20/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import UIKit
import MapKit
import Async

class MapViewController: UIViewController {
	@IBOutlet weak var pokemap: MKMapView!
	@IBOutlet weak var scanButton: UIButton!
	@IBOutlet weak var progress: UIProgressView!

	var locationManager: CLLocationManager = CLLocationManager()
	var client = Skiplagged()
	let maxSearchAltitude: Double = 75000
	var searchCountdown: Timer? = nil
	var firstSearchQueued = false

	override func viewDidLoad() {
		super.viewDidLoad()
		self.pokemap.delegate = self
		client.inhibitScan = true
		progress.isHidden = true
		progress.setProgress(0.0, animated: false)

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

}

// MARK: - Skiplagged functions
extension MapViewController {

	func initializeSkiplaggedConnection() {

		Async.background {
			while !self.client.getSpecificAPIEndpoint().success {
				Thread.sleep(forTimeInterval: 0.5)
				printTimestamped("Unable to retrieve specific endpoint. Retrying...")
			}

			while !self.client.getProfile().success {
				Thread.sleep(forTimeInterval: 0.5)
				printTimestamped("Unable to retrieve profile. Retrying...")
			}

			if self.locationManager.location != nil {
				self.searchMap(self.pokemap)
			} else {
				self.firstSearchQueued = true
			}

		}
	}

	func searchMap(_ mapView: MKMapView) {
		if self.pokemap.camera.altitude < maxSearchAltitude {
			let latDelt = mapView.region.span.latitudeDelta/2
			let longDelt = mapView.region.span.latitudeDelta/2
			let center = mapView.region.center
			let queue = AsyncGroup()

			Async.background {
				let bottomLeft = (center.latitude - latDelt, center.longitude - longDelt)
				let topRight = (center.latitude + latDelt, center.longitude + longDelt)

				self.client.findPokemon(bounds: (bottomLeft, topRight), progress: {
					progress in
					Async.main {
						self.progress.setProgress(Float(progress), animated: true)

					}
					}, completion: {
						foundPokemon in
						queue.enter()
						Async.main {
							self.scanButton.isHidden = true
							}.background {
								for pokemon in foundPokemon {
									if pokemon.isUnique(pokemons: mapView.annotations) {
										Async.main {
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
								queue.leave()
						}
				})

				queue.wait()
				}.main {
					// TODO: Change scan button image, and show

					self.scanButton.isHidden = false
					self.progress.isHidden = true
			}
		}
	}

	func removePokemonfromTimer(timer: Timer) {
		Async.main {
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
			pokeDetail.annotation = annotation
			pokeDetail.isEnabled = true
			pokeDetail.image = UIImage(named: "\(pokemon.dexID)")
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

	func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
		//self.client.cancelSearch()
		client.inhibitScan = true
		if self.searchCountdown != nil {
			self.searchCountdown!.invalidate()
			self.searchCountdown = nil
		}
		Async.main {
			self.scanButton.isHidden = false
			self.progress.isHidden = true
		}
	}

	func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

		if mapView.userTrackingMode == .followWithHeading
			|| mapView.userTrackingMode == .follow {

			//TODO: Search Map

			//			if client.scanReady {
			//				self.searchMap(mapView)
			//			} else {
			//				return
			//			}

		}

		if #available(iOS 10.0, *) {
			self.searchCountdown = Timer(fire: Date(timeIntervalSinceNow: 3),
			                             interval: 0.0, repeats: false) {
											(timer) in
											self.client.inhibitScan = false
											self.searchMap(mapView)
											Async.main {
												self.scanButton.isHidden = true
												self.progress.setProgress(0.0, animated: false)
												self.progress.isHidden = false
											}
			}
			RunLoop.current.add(self.searchCountdown!, forMode: .commonModes)
		} else {
			// TODO: Timer: Fallback on earlier versions
		}
	}
}


// MARK: - Location Functions
extension MapViewController: CLLocationManagerDelegate {

	@IBAction func gotoCurrentLocation(_ sender: AnyObject) {
		self.pokemap.setUserTrackingMode(.followWithHeading, animated: true)
	}

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if checkLocationAuthorization() != nil {
			gotoCurrentLocation(self)
		}
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: NSError) {
		print("Location error: \(error.localizedDescription)")
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if self.firstSearchQueued {
			self.firstSearchQueued = false
			searchMap(self.pokemap)
		}
	}
}

extension MapViewController {

}
