//
//  LoginViewController.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/28/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import UIKit
import MapKit

class LoginViewController: UIViewController {
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}

	let client = Skiplagged()

	@IBOutlet weak var teamImage: UIImageView!
	@IBOutlet weak var googleButton: UIButton!
	@IBOutlet weak var ptcButton: UIButton!
	@IBOutlet weak var usernameField: UITextField!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var cancelButton: UIButton!
	@IBOutlet weak var secretButton: UIButton!
	@IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
	@IBOutlet weak var progressIndicator: UIProgressView!

	let locationMananger = CLLocationManager()

	override func viewDidLoad() {
		super.viewDidLoad()
		if let team = UserDefaults.standard.string(forKey: "team") {
			setTeam(to: team)
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
		if let pokemap = segue.destination as? MapViewController {

			pokemap.client = self.client
		}
	}
}


// MARK: - Login functions

extension LoginViewController {

	@IBAction func beginLogin(_ sender: UIButton) {
		self.view.endEditing(false)
		self.locationMananger.requestAlwaysAuthorization()
		showLoading(true)
		guard let username = usernameField.text,
			let password = passwordField.text,
			username.characters.count > 2,
			password.characters.count > 2
			else {
				//TODO: Alert user of bad login


				displayInfo(title: "Invalid Login", message: "Invalid Login", response: "Retry")


				showLoading(false)
				return
		}

		// Skip login if user already has login info ticket
		if username == UserDefaults.standard.string(forKey: "username")
			&& password == UserDefaults.standard.string(forKey: "password")
			&& client.isLoggedOn() {

			while CLLocationManager.authorizationStatus() == .notDetermined {
				self.locationMananger.requestAlwaysAuthorization()
				// TODO: Check Logic
			}

			if CLLocationManager.authorizationStatus() != .authorizedAlways {
				authorizationAlert(controller: self, settings: {
					self.showLoading(false)
					}, cancel: {
						self.showLoading(false)
				})
				return
			}

			var progress: LoginSteps = .Started
			self.client.initializeConnection(statusUpdate: {
				status in
				if status.rawValue > progress.rawValue {
					progress = status
				}
				self.setProgress(status: progress, force: true)

				self.verifyProgress(status: status)

				}, canceled: {
					self.showLoading(false)
			}) {
				// TODO: Modify to allow for timeout alert
				DispatchQueue.main.async {
					self.performSegue(withIdentifier: "loggedin", sender: self)
				}
			}
			return
		}

		// otherwise login normally
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

	@IBAction func cancelLogin() {
		// TODO:
		cancelButton.isEnabled = false
		cancelButton.isHidden = true
		client.cancelLogin = true
	}

	func verifyProgress(status: LoginSteps) {
		struct Fail {
			static var count = 0
			static var highestStep: LoginSteps = .Started
		}

		if status.rawValue > Fail.highestStep.rawValue {
			Fail.highestStep = status
			Fail.count = 0
		} else if status == Fail.highestStep {
			Fail.count += 1

			if Fail.count == 10 {
				let alert = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
				alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
				alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
					alertAction in

					// TODO: Cancel Login
					self.cancelLogin()
				}))

				switch Fail.highestStep {
				case .APIEndpoint1, .APIEndpoint2, .APIEndpoint3:
					alert.title = "This is taking awhile..."
					alert.message = "Possible scan server outage"
					break
				default:
					break
				}

				self.present(alert, animated: true, completion: nil)
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

		DispatchQueue.global(qos: .userInitiated).async {
			let result = self.client.loginWithPTC(username, password: password) {
				status in
				self.setProgress(status: status, force: true)

			}

			switch result {
			case .Failure(let error):
				printTimestamped("Login Failed: " + error.debugDescription)
				if let statusCode = error.userInfo["StatusCode"] as? Int {
					switch statusCode {
					case 503:
						self.displayInfo(title: "Server Outage", message: "Pokemon Trainer Club is down")
					default:
						// TODO:
						self.displayInfo(title: "Login Failed", message: "Haven't specified what yet")
						break
					}
				}
				self.showLoading(false)
			// TODO Alert User
			case .Success():
				printTimestamped("Login Successful")
				DispatchQueue.main.async {
					UserDefaults.standard.setValue(username, forKey: "username")
					// TODO: Store password securely
					UserDefaults.standard.setValue(password, forKey: "password")
					UserDefaults.standard.setValue("ptc", forKey: "provider")

					while CLLocationManager.authorizationStatus() == .notDetermined {
						self.locationMananger.requestAlwaysAuthorization()
						// TODO: Check Logic
					}

					if CLLocationManager.authorizationStatus() != .authorizedAlways {
						authorizationAlert(controller: self,
						                   settings: { self.showLoading(false) },
						                   cancel: { self.showLoading(false) })
						return
					}

					var progress: LoginSteps = .Started
					self.client.initializeConnection(statusUpdate: {
						status in
						if status.rawValue > progress.rawValue {
							progress = status
						}
						self.setProgress(status: progress, force: true)
						self.setProgress(status: status)
						self.verifyProgress(status: status)

					}, canceled: {
						self.showLoading(false)
					}) {
						// TODO: Modify to allow for timeout alert
						DispatchQueue.main.async {
							self.performSegue(withIdentifier: "loggedin", sender: self)
						}
					}
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
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
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
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
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

}

// MARK: - UI and Animations
extension LoginViewController {

	func showLoading(_ answer: Bool) {
		DispatchQueue.main.async {
			if answer {
				self.loadingIndicator.startAnimating()
			} else {
				self.loadingIndicator.stopAnimating()
			}

			self.cancelButton.isEnabled = answer
			self.cancelButton.isHidden = !answer
			self.progressIndicator.isHidden = !answer
			self.usernameField.isHidden = answer
			self.passwordField.isHidden = answer
			self.googleButton.isHidden = answer
			self.ptcButton.isHidden = answer
		}
	}

	func setTeam(to: String) {
		// swiftlint:disable line_length
		switch to {
		case "harmony":
			self.teamImage.image = UIImage(named: "Harmony_large")
			self.loadingIndicator.color = #colorLiteral(red: 0.2431372549, green: 0.6431372549, blue: 0.6823529412, alpha: 1)
			self.progressIndicator.progressTintColor = #colorLiteral(red: 0.2431372549, green: 0.6431372549, blue: 0.6823529412, alpha: 1)
			UserDefaults.standard.set("harmony", forKey: "team")
		case "valor":
			self.teamImage.image = UIImage(named: "Valor_large")
			self.loadingIndicator.color = #colorLiteral(red: 0.9137254902, green: 0.1725490196, blue: 0.1725490196, alpha: 1)
			self.progressIndicator.progressTintColor = #colorLiteral(red: 0.9137254902, green: 0.1725490196, blue: 0.1725490196, alpha: 1)
			UserDefaults.standard.set("valor", forKey: "team")
		case "mystic":
			self.teamImage.image = UIImage(named: "Mystic_large")
			self.loadingIndicator.color = #colorLiteral(red: 0.231372549, green: 0.4588235294, blue: 0.7450980392, alpha: 1)
			self.progressIndicator.progressTintColor = #colorLiteral(red: 0.231372549, green: 0.4588235294, blue: 0.7450980392, alpha: 1)
			UserDefaults.standard.set("mystic", forKey: "team")
		case "instinct":
			self.teamImage.image = UIImage(named: "Instinct_large")
			self.loadingIndicator.color = #colorLiteral(red: 0.9921568627, green: 0.831372549, blue: 0.1254901961, alpha: 1)
			self.progressIndicator.progressTintColor = #colorLiteral(red: 0.9921568627, green: 0.831372549, blue: 0.1254901961, alpha: 1)
			UserDefaults.standard.set("instinct", forKey: "team")
		default:
			self.teamImage.image = UIImage(named: "Harmony_large")
			self.loadingIndicator.color = #colorLiteral(red: 0.2431372549, green: 0.6431372549, blue: 0.6823529412, alpha: 1)
			self.progressIndicator.progressTintColor = #colorLiteral(red: 0.2431372549, green: 0.6431372549, blue: 0.6823529412, alpha: 1)
			UserDefaults.standard.set("harmony", forKey: "team")
		}
		// enable line_length
	}

	@IBAction func changeTeamImage() {
		if let team = UserDefaults.standard.string(forKey: "team") {
			switch team {
			case "harmony":
				setTeam(to: "valor")
			case "valor":
				setTeam(to: "mystic")
			case "mystic":
				setTeam(to: "instinct")
			case "instinct":
				setTeam(to: "harmony")
			default:
				setTeam(to: "harmony")
			}
		} else {
			// starts at harmony, next in rotation is Valor
			setTeam(to: "valor")
		}
	}

	// Progress is updated only when it has gone forward
	// if forced it will use any value, good for restarting after login cancelled
	func setProgress(status: LoginSteps, force: Bool = false) {
		DispatchQueue.main.async {
			let progress: Float = Float(status.rawValue) / Float(LoginSteps.Complete.rawValue)
			if force {
				self.progressIndicator.setProgress(progress, animated: true)
			} else {
				if progress > self.progressIndicator.progress {
					self.progressIndicator.setProgress(progress, animated: true)
				}
			}
		}
	}

	func displayInfo(title: String?, message: String?, response: String? = "OK") {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: response, style: .default, handler: nil))
		DispatchQueue.main.async {
			self.present(alert, animated: true, completion: nil)
		}
	}
}
