//
//  CreateAccountViewController.swift
//  hackillinois-2017-ios
//
//  Created by Shotaro Ikeda on 6/21/16.
//  Copyright © 2016 Shotaro Ikeda. All rights reserved.
//

import UIKit
import SwiftyJSON

class CreateAccountViewController: GenericInputView {
    /* Navigation */
    @IBOutlet weak var navigationBar: UINavigationBar!

    /* Button presses */
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.view.endEditing(true)
        /* Confirm user if they want to actually cancel */
        let ac = UIAlertController(title: "Cancel Creating Account?", message: "Are you sure you would like to cancel creating your account? All changes will be lost.", preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Destructive, handler: { [unowned self] _ in self.dismissViewControllerAnimated(true, completion: nil) }))
        ac.addAction(UIAlertAction(title: "Undo", style: .Cancel, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    /* Function passed to capture the response data */
    func captureResponse(data: NSData?, response: NSURLResponse?, error: NSError?) {
        if let responseError = error {
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                self.presentError(error: "Error", message: responseError.localizedDescription)
            }
            return
        }
        
        let json = JSON(data: data!)
        
        print("data received")
        print(json)
        
        /* Restore Navigation Bar to regular status */
        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
            // Title bar configuration
            self.navigationBar.topItem?.title = "Create Account"
            self.navigationBar.topItem?.titleView = nil
            // Disable Buttons
            self.navigationBar.topItem?.leftBarButtonItem?.enabled = true
            self.navigationBar.topItem?.rightBarButtonItem?.enabled = true
        }
        
        /* Handle Errors */
        if !json["error"].isEmpty {
            print("error detected")
            if json["error"]["type"].stringValue == "InvalidParameterError" && json["error"]["source"].stringValue == "email" {
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    self.presentError(error: "Duplicate Email", message: "An account with the email already exists. Please check your email or visit the main website to reset your password")
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    self.presentError(error: json["error"]["title"].stringValue, message: json["error"]["message"].stringValue)
                }
            }
            return
        } else {
            /* Error free -- parse data */
            print("data integrity passed!")
        }
    }
    
    @IBAction func doneButtonPressed(sender: AnyObject) {
        /* Check to see if everything is working */
        self.view.endEditing(true)
        
        // Check all fields for input
        if usernameField.text == "" || passwordField.text == "" || confirmPasswordField.text == "" {
            presentError(error: "Empty Fields Found", message: "All fields are required to create an account")
            return
        }
        
        if !stringIsEmail(usernameField.text!) {
            // Username is not an email
            presentError(error: "Invalid Email", message: "Inputted Email is not valid")
            return
        }
        
        if passwordField.text!.utf8.count < 8 {
            presentError(error: "Password Too Short", message: "Password must be at least 8 characters long")
            return
        }
        
        if !(passwordField.text! == confirmPasswordField.text!) {
            presentError(error: "Password fields do not match", message: "Password Fields do not match please try again.")
            return
        }
        
        /* Activity Indicator */
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator.startAnimating()
        navigationBar.topItem?.title = ""
        navigationBar.topItem?.titleView = activityIndicator
        // Disable Buttons
        navigationBar.topItem?.leftBarButtonItem?.enabled = false
        // navigationBar.topItem?.leftBarButtonItem?.tintColor = UIColor.grayColor()
        navigationBar.topItem?.rightBarButtonItem?.enabled = false
        // navigationBar.topItem?.rightBarButtonItem?.tintColor = UIColor.grayColor()
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { [unowned self] in
            let payload = JSON(["email": self.usernameField.text!, "password": self.passwordField.text!, "confirmedPassword": self.confirmPasswordField.text!])
            print(payload)
            HTTPHelpers.createPostRequest(subUrl: "v1/user", jsonPayload: payload, completion: self.captureResponse)
        }
    }
    
    /* Text Fields */
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    
    /* Scroll View */
    @IBOutlet weak var scrollView: UIScrollView!
    
    /* Utility functions */
    func presentError(error title: String, message: String) {
        /* Present error with just a cancel option */
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    func stringIsEmail(email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluateWithObject(email)
    }
    
    override func viewDidLoad() {
        /* Configure super classes' variables */
        scroll = scrollView
        textFields = [usernameField, passwordField, confirmPasswordField]
        textViews = []
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}