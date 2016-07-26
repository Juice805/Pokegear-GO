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
            printTimestamped("Login Successful" + "\n\n")
            
            client.getSpecificAPIEndpoint() { (specificAPIEndpointResult) in
                switch specificAPIEndpointResult {
                case .Failure(let error):
                    printTimestamped("JUICE- ERROR: " + error.debugDescription)
                    return
                case .Success(let answer):
                    printTimestamped("JUICE- Specific API SUCCESS: " + answer! + "\n\n")
                
                    client.getProfile() { (profileResult) in
                        switch profileResult {
                        case .Failure(let error):
                            printTimestamped("JUICE- ERROR: " + error.debugDescription)
                            return
                        case .Success(let profile):
                            print(profile.debugDescription + "\n\n")
                            
                            client.findPokemon(bounds: ((34.408359, -119.869816), (34.420923, -119.840293)))
                            
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
    

    
    
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
}

extension MapViewController {
    func testCallSkipplagged(client: Skiplagged){
        let data: [String:AnyObject] = ["access_token": client.ACCESS_TOKEN!,
                    "auth_provider": client.AUTH_PROVIDER!
        ]
        
        print("JUICE- INPUT DATA: " + data.debugDescription)
        
        client.call(Skiplagged.SKIPLAGGED_API, data: data) { (anyResult) in
            switch anyResult {
            case .Failure(let error):
                printTimestamped(error.debugDescription)
                break
            case .Success(let data):
                if let json = data as? [String: AnyObject] {
                    print("JUICE- RESULT: " + json.debugDescription)
                    
                    
                    client.call(Skiplagged.GENERAL_API, data: json["pdata"]!) { (jsonResult) in
                        switch jsonResult {
                        case .Failure(let error):
                            printTimestamped("JUICE- ERROR: " + error.debugDescription)
                            break
                        case .Success(let data):
                            if let json = JSON(data!).dictionaryObject {
                                print("JUICE- RESULT: " + json.description)
                            } else {
                                printTimestamped("JUICE- ERROR: " + data.debugDescription)
                            }
                            break
                            
                        }
                    }
                } else {
                    printTimestamped("JUICE- ERROR: " + data.debugDescription)
                }
                break
                
            }
        }
    }
    
    func testCallNiantic(client: Skiplagged){
        let data: [String:AnyObject] = ["access_token": client.ACCESS_TOKEN!,
                                        "auth_provider": client.AUTH_PROVIDER!
        ]
        
        print("JUICE- INPUT DATA: " + data.debugDescription)
        
        client.call(Skiplagged.SKIPLAGGED_API, data: data) { (jsonResult) in
            switch jsonResult {
            case .Failure(let error):
                printTimestamped(error.debugDescription)
                break
            case .Success(let data):
                if let json = JSON(data!).dictionaryObject {
                    print("JUICE- RESULT: " + json.description)
                } else {
                    printTimestamped("JUICE- ERROR: " + data.debugDescription)
                }
                break
                
            }
        }
    }
}
