//
//  LoginViewController.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/28/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import UIKit
import Async
import MapKit

class LoginViewController: UIViewController {

    let client = Skiplagged()

    @IBOutlet weak var teamImage: UIImageView!
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var ptcButton: UIButton!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var secretButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    let locationMananger = CLLocationManager()

	override func viewDidLoad() {
		super.viewDidLoad()
		if let team = UserDefaults.standard.string(forKey: "team") {
			// swiftlint:disable line_length
			switch team {
			case "harmony":
				self.teamImage.image = UIImage(named: "Harmony_large")
				self.loadingIndicator.color = #colorLiteral(red: 0.2431372549, green: 0.6431372549, blue: 0.6823529412, alpha: 1)
			case "valor":
				self.teamImage.image = UIImage(named: "Valor_large")
				self.loadingIndicator.color = #colorLiteral(red: 0.9137254902, green: 0.1725490196, blue: 0.1725490196, alpha: 1)
			case "mystic":
				self.teamImage.image = UIImage(named: "Mystic_large")
				self.loadingIndicator.color = #colorLiteral(red: 0.231372549, green: 0.4588235294, blue: 0.7450980392, alpha: 1)
			case "instinct":
				self.teamImage.image = UIImage(named: "Instinct_large")
				self.loadingIndicator.color = #colorLiteral(red: 0.9921568627, green: 0.831372549, blue: 0.1254901961, alpha: 1)
			default:
				self.teamImage.image = UIImage(named: "Harmony_large")
				self.loadingIndicator.color = #colorLiteral(red: 0.2431372549, green: 0.6431372549, blue: 0.6823529412, alpha: 1)
			}
			// enable line_length
		}
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(keyboardWillShow(notification:)),
		                                       name: NSNotification.Name.UIKeyboardWillShow,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(keyboardWillHide(notification:)),
		                                       name: NSNotification.Name.UIKeyboardWillHide,
		                                       object: nil)
		showLoading(true)
		if !loginFromUserDefaults() {
			showLoading(false)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func showLoading(_ answer: Bool) {
        Async.main {
            if answer {
                self.loadingIndicator.startAnimating()
            } else {
                self.loadingIndicator.stopAnimating()
            }
            self.usernameField.isHidden = answer
            self.passwordField.isHidden = answer
            self.googleButton.isHidden = answer
            self.ptcButton.isHidden = answer
        }
    }

    @IBAction func changeTeamImage() {
        //TODO: Change Image

        if let team = UserDefaults.standard.string(forKey: "team") {
            switch team {
            case "harmony":
                self.teamImage.image = UIImage(named: "Valor_large")
                self.loadingIndicator.color = #colorLiteral(red: 0.9137254902, green: 0.1725490196, blue: 0.1725490196, alpha: 1)
                UserDefaults.standard.set("valor", forKey: "team")
            case "valor":
                self.teamImage.image = UIImage(named: "Mystic_large")
                self.loadingIndicator.color = #colorLiteral(red: 0.231372549, green: 0.4588235294, blue: 0.7450980392, alpha: 1)
                UserDefaults.standard.set("mystic", forKey: "team")
            case "mystic":
                self.teamImage.image = UIImage(named: "Instinct_large")
                self.loadingIndicator.color = #colorLiteral(red: 0.9921568627, green: 0.831372549, blue: 0.1254901961, alpha: 1)
                UserDefaults.standard.set("instinct", forKey: "team")
            case "instinct":
                self.teamImage.image = UIImage(named: "Harmony_large")
                self.loadingIndicator.color = #colorLiteral(red: 0.2431372549, green: 0.6431372549, blue: 0.6823529412, alpha: 1)
                UserDefaults.standard.set("harmony", forKey: "team")
            default:
                self.teamImage.image = UIImage(named: "Harmony_large")
                self.loadingIndicator.color = #colorLiteral(red: 0.2431372549, green: 0.6431372549, blue: 0.6823529412, alpha: 1)
                UserDefaults.standard.set("harmony", forKey: "team")
            }
        } else {
            self.teamImage.image = UIImage(named: "Valor_large")
            self.loadingIndicator.color = #colorLiteral(red: 0.9137254902, green: 0.1725490196, blue: 0.1725490196, alpha: 1)
            UserDefaults.standard.set("valor", forKey: "team")
        }
    }

    @IBAction func whyNotPrimary(_ sender: AnyObject) {
        // TODO: Show popup explaining the system
    }
}


// MARK: - Navigation

extension LoginViewController {

    override func shouldPerformSegue(withIdentifier identifier: String, sender: AnyObject?) -> Bool {
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            return false
        } else {
            return true
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let pokemap = segue.destinationViewController as? MapViewController {

            pokemap.client = self.client
        }
    }
}


// MARK: - Login functions

extension LoginViewController {
    @IBAction func beginLogin(_ sender: UIButton) {
        self.locationMananger.requestAlwaysAuthorization()
        showLoading(true)
        guard let username = usernameField.text,
            let password = passwordField.text,
            username != "",
            password != ""
            else {
                //TODO: Alert user of bad login
                showLoading(false)
                return
        }
        if let id = sender.restorationIdentifier {
            switch id {
            case "ptc":
                self.trainerClubLogin(username: username, password: password)
                break
            case "google":
                self.googleLogin(username: username, password: password)
            default: return
            }
        }
    }

	func loginFromUserDefaults() -> (Bool) {
		if let username = UserDefaults.standard.string(forKey: "username"),
			let password = UserDefaults.standard.string(forKey: "password"),
			let provider = UserDefaults.standard.string(forKey: "provider") {
			self.usernameField.text = username
			switch provider {
			case "ptc":
				trainerClubLogin(username: username, password: password)
			case "google":
				// TODO: Google
				googleLogin(username: username, password: password)
				break
			default:
				break
			}
			return true
		} else {
			return false
		}
	}

    func trainerClubLogin(username: String, password: String) {
        printTimestamped(username + ", " + password)

        client.loginWithPTC(usernameField.text!, password: passwordField.text!) {
            result in
            switch result {
            case .Failure(let error):
                printTimestamped("Login Failed: " + error.debugDescription)
                self.showLoading(false)
            // TODO Alert User
            case .Success():
                printTimestamped("Login Successful")
                Async.main {
                    UserDefaults.standard.setValue(self.usernameField.text, forKey: "username")
                    // TODO: Store password securely
                    UserDefaults.standard.setValue(self.passwordField.text, forKey: "password")
                    UserDefaults.standard.setValue("ptc", forKey: "provider")

                    while CLLocationManager.authorizationStatus() == .notDetermined {
                        self.locationMananger.requestAlwaysAuthorization()
                        // TODO: Check Logic
                    }

                    self.performSegue(withIdentifier: "loggedin", sender: self)
                }
            }

        }
    }

    func googleLogin(username: String, password: String) {
        //TODO: Google Login
    }
}



// MARK: - Location Manager

extension LoginViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status != .authorizedAlways {
            //TODO: Alert User location is required
        }
    }
}


// MARK: - Keyboard and Textfield functions
extension LoginViewController {
    @IBAction func dismissKeyboard() {
        self.view.endEditing(false)
    }

    @IBAction func nextField(_ sender: UITextField) {
        if sender.restorationIdentifier == "username" {
            passwordField.becomeFirstResponder()
        }
    }

    func keyboardWillShow(notification: NSNotification) {
        secretButton.isHidden = true
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue() {
            //if view.frame.origin.y == 0{

            // checks if view needs to move
            // origin is top left
            let googleButtonHeight = self.view.bounds.height - (self.googleButton.frame.origin.y + self.googleButton.frame.height)

            if keyboardSize.height > googleButtonHeight - 20 {
                if view.bounds.origin.y == 0 {

                    let offset =  20 + keyboardSize.height - googleButtonHeight

                    UIView.animate(withDuration: 0.5, animations: {
                        // self.view.frame.origin.y -= keyboardSize.height - 150
                        self.view.bounds = self.view.bounds.offsetBy(dx: 0, dy: offset)
                    })
                } else {

                }
            }
        }
    }

    func keyboardWillHide(notification: NSNotification) {
        secretButton.isHidden = false
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue() {
            //if view.frame.origin.y != 0 {
            if view.bounds.origin.y != 0 {
                // origin is top left
                let googleButtonHeight = self.view.bounds.height - (self.googleButton.frame.origin.y + self.googleButton.frame.height)

                let offset =  20 + keyboardSize.height - googleButtonHeight


                UIView.animate(withDuration: 0.5, animations: {

                    self.view.bounds = self.view.bounds.offsetBy(dx: 0, dy: -offset)

                })
            } else {

            }
        }
    }

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .portrait
    }

}
