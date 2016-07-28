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
import SwiftyJSON

class MapViewController: UIViewController {
    
    @IBOutlet weak var pokemap: MKMapView!
    
    var LocationManager: CLLocationManager? = nil
    let client = Skiplagged()
    let maxSearchAltitude: Double = 75000

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.pokemap.delegate = self
        
        self.LocationManager = checkLocationAuthorization()
        
        if self.LocationManager == nil {
            // TODO: Alert User to grant location access
            self.LocationManager = checkLocationAuthorization()
        }
        
        
        if self.LocationManager != nil {
            gotoCurrentLocation(self)
        }
        
        
        
        self.client.loginWithPTC("WhiskeyJuice", password: "pokemon") { () in
            printTimestamped("Login Successful" + "\n\n")
            
            self.client.getSpecificAPIEndpoint() { (specificAPIEndpointResult) in
                switch specificAPIEndpointResult {
                case .Failure(let error):
                    printTimestamped("JUICE- ERROR: " + error.debugDescription)
                    return
                case .Success(let answer):
                    printTimestamped("JUICE- Specific API SUCCESS: " + answer! + "\n\n")
                    
                    self.client.getProfile() { (profileResult) in
                        switch profileResult {
                        case .Failure(let error):
                            printTimestamped("JUICE- ERROR: " + error.debugDescription)
                            return
                        case .Success(let profile):
                            print(profile.debugDescription + "\n\n")
                            
                            if (self.LocationManager?.location) != nil && self.pokemap.camera.altitude < self.maxSearchAltitude{
                                let latDelt = self.pokemap.region.span.latitudeDelta/2
                                let longDelt = self.pokemap.region.span.latitudeDelta/2
                                let center = self.pokemap.region.center
                                let bottomLeft: (Double, Double) = (center.latitude - latDelt, center.longitude - longDelt)
                                let topRight: (Double, Double) = (center.latitude + latDelt, center.longitude + longDelt)
                                self.client.findPokemon(bounds: ((bottomLeft), (topRight))) {
                                    foundPokemon in
                                    for pokemon in foundPokemon {
                                        Async.main {
                                            self.pokemap.addAnnotation(pokemon)
                                        }
                                    }
                                }
                                
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkLocationAuthorization() -> CLLocationManager? {
        let LocationManager = CLLocationManager()
        
        switch CLLocationManager.authorizationStatus() {
        case .denied, .restricted:
            // User has denied access to location
            return nil
        case .notDetermined:
            
            LocationManager.requestAlwaysAuthorization()
            print("Requesting Location Authorization")
            
            if CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .restricted || CLLocationManager.authorizationStatus() == .notDetermined {
                // User has denied access to location
                print("Authorization not granted")
                return nil
                
            }
            
        default:
            // App is allowed
            print("App is authorized for location services")
        }
        
        LocationManager.startUpdatingLocation()
        
        return LocationManager
    }
    
    @IBAction func gotoCurrentLocation(_ sender: AnyObject) {
        
        self.pokemap.setUserTrackingMode(.followWithHeading, animated: true)
        
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        
        let pokeDetail = MKAnnotationView()
        
        if let pokemon = annotation as? Pokemon {
            pokeDetail.image = UIImage(named: "\(pokemon.id)")
        } else {
            
        }
        
        return pokeDetail
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.client.cancelSearch()
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if client.PROFILE_RAW == nil {
            return
        }
        
        self.client.cancelSearch()
        
        if LocationManager != nil && self.pokemap.camera.altitude < maxSearchAltitude {
            let latDelt = mapView.region.span.latitudeDelta/2
            let longDelt = mapView.region.span.latitudeDelta/2
            let center = mapView.region.center
            client.findPokemon(bounds: ((center.latitude - latDelt, center.longitude - longDelt),
                                        (center.latitude + latDelt, center.longitude + longDelt))) {
                                            foundPokemon in
                                            Async.background{
                                                
                                                for pokemon in foundPokemon {
                                                    if pokemon.isUnique(pokemons: mapView.annotations) {
                                                        Async.main {
                                                            self.pokemap.addAnnotation(pokemon)
                                                        }
                                                        
                                                        if #available(iOS 10.0, *) {
                                                            pokemon.timer = Timer(fire: pokemon.expireTime, interval: 0.0, repeats: false, block:
                                                                { (timer) in
                                                                    self.pokemap.removeAnnotation(pokemon)
                                                            })
                                                            RunLoop.current.add(pokemon.timer!, forMode: RunLoopMode.commonModes)
                                                        } else {
                                                            // Fallback on earlier versions
                                                            pokemon.timer = Timer(fireAt: pokemon.expireTime,
                                                                                  interval: 0.0, target: self,
                                                                                  selector: #selector(self.removePokemonfromTimer),
                                                                                  userInfo: pokemon, repeats: false)
                                                            
                                                        }
                                                    }
                                                }
                                            }
            }
        }
        
    }
    
    func removePokemonfromTimer(timer: Timer){
        self.pokemap.removeAnnotation(timer.userInfo as! Pokemon)
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
}

extension MapViewController {
    
}



