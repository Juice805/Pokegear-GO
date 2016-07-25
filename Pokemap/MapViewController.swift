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
    
    var LocationManager: CLLocationManager? = nil
    
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
        
        
        let client = Skiplagged()
        
        client.loginWithPTC("WhiskeyJuice", password: "pokemon") { () in
            printTimestamped("Login Successful")
            
                client.getSpecificAPIEndpoint({ (specificAPIEndpointResult) in
                    switch specificAPIEndpointResult {
                    case .Failure(let error):
                        printTimestamped(error.description)
                        break
                    case .Success(let specificAPIEndpoint):
                        printTimestamped("SUCCESS")
                        break
                    }
                })
            
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
        
        LocationManager.delegate = self
        LocationManager.startUpdatingLocation()
        
        return LocationManager
    }

    @IBAction func gotoCurrentLocation(_ sender: AnyObject) {
        
        self.pokemap.setUserTrackingMode(.followWithHeading, animated: true)
        
    }
}

extension MapViewController: MKMapViewDelegate {
    

    
    
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
}
