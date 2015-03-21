//
//  ProfileViewController.swift
//  ble-swift
//
//  Created by Yuan on 15/3/19.
//  Copyright (c) 2015年 xuyuanme. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class ProfileViewController: UIViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {
    @IBOutlet weak var usernameLabel: UILabel!
    
    override func viewDidLoad() {
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        var user = PFUser.currentUser()
        if(user == nil) {
            showLoginView()
        } else {
            usernameLabel.text = user.username
        }
    }
    
    func logInViewController(logInController: PFLogInViewController!, didLogInUser user: PFUser!) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func logInViewController(logInController: PFLogInViewController!, didFailToLogInWithError error: NSError!) {
        Logger.debug("\(error)")
    }

    func logInViewControllerDidCancelLogIn(logInController: PFLogInViewController!) {
        Logger.debug("ProfileViewController#logInViewControllerDidCancelLogIn")
    }
    
    func signUpViewController(signUpController: PFSignUpViewController!, didSignUpUser user: PFUser!) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func signUpViewController(signUpController: PFSignUpViewController!, didFailToSignUpWithError error: NSError!) {
        Logger.debug("\(error)")
    }
    
    func signUpViewControllerDidCancelSignUp(signUpController: PFSignUpViewController!) {
        Logger.debug("ProfileViewController#signUpViewControllerDidCancelSignUp")
    }
    
    @IBAction func logoutButtonClicked(sender: AnyObject) {
        PFUser.logOut()
        usernameLabel.text = ""
        showLoginView()
    }
    
    private func showLoginView() {
        var logInController = PFLogInViewController()
        logInController.fields = PFLogInFields.UsernameAndPassword | PFLogInFields.LogInButton | PFLogInFields.SignUpButton | PFLogInFields.PasswordForgotten
        var loginLabel = UILabel(frame: CGRectMake(0, 0, 0, 0))
        loginLabel.text = "Flipped"
        logInController.logInView.logo = loginLabel
        var signupLabel = UILabel(frame: CGRectMake(0, 0, 0, 0))
        signupLabel.text = "Flipped"
        logInController.signUpController.signUpView.logo = signupLabel
        logInController.delegate = self
        logInController.signUpController.delegate = self
        self.presentViewController(logInController, animated:true, completion: nil)
    }
    
}