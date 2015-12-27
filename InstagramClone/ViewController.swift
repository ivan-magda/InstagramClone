//
//  ViewController.swift
//  InstagramClone
//
//  Created by Иван Магда on 25.12.15.
//  Copyright © 2015 Ivan Magda. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController {
    // MARK: - Properties
    
    var signupActive = true
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var registedLabel: UILabel!
    @IBOutlet weak var logInButton: UIButton!
    
    var activityIndicator = UIActivityIndicatorView()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if PFUser.currentUser() != nil {
            self.performSegueWithIdentifier("login", sender: self)
        }
    }
    
    // MARK: - Private
    
    private func presentAlertWithTitle(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default) { action in
            self.dismissViewControllerAnimated(true, completion: nil)
            })
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func signUp(sender: AnyObject) {
        if username.text == "" || password.text == "" {
            presentAlertWithTitle("Error in form", message: "Please enter username and password")
        } else {
            self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            self.activityIndicator.center = self.view.center
            self.activityIndicator.hidesWhenStopped = true
            self.view.addSubview(self.activityIndicator)
            self.activityIndicator.startAnimating()
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
            
            if signupActive {
                
                let user = PFUser()
                user.username = username.text
                user.password = password.text
                
                user.signUpInBackgroundWithBlock() { (successed, error) in
                    self.activityIndicator.stopAnimating()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    
                    if let error = error {
                        var message: String?
                        if let errorInfo = error.userInfo["error"] as? String {
                            message = errorInfo
                        }
                        self.presentAlertWithTitle("Failed SingUp", message: message)
                    } else {
                        self.performSegueWithIdentifier("login", sender: self)
                    }
                }
                
            } else {
                PFUser.logInWithUsernameInBackground(username.text!, password: password.text!) { (user, error) in
                    self.activityIndicator.stopAnimating()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    
                    if let user = user {
                        debugPrint(user)
                        self.performSegueWithIdentifier("login", sender: self)
                    } else {
                        if error != nil, let message = error!.userInfo["error"] as? String {
                            self.presentAlertWithTitle("Failed LogIn", message: message)
                        }
                        self.presentAlertWithTitle("Failed LogIn", message: "Try again")
                    }
                }
            }
        }
    }
    
    @IBAction func logIn(sender: AnyObject) {
        if signupActive == true {
            signupActive = false
            
            self.signUpButton.setTitle("Log In", forState: UIControlState.Normal)
            self.registedLabel.text = "Not registed?"
            self.logInButton.setTitle("Sign Up", forState: UIControlState.Normal)
        } else {
            signupActive = true
            
            self.signUpButton.setTitle("Sign Up", forState: UIControlState.Normal)
            self.registedLabel.text = "Alreay registed?"
            self.logInButton.setTitle("Log In", forState: UIControlState.Normal)
        }
    }
}

