//
//  UserIdentityViewController.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.12
//

import Foundation
import UIKit
import AWSMobileHubHelper
import FBSDKLoginKit
import FBSDKCoreKit
import GoogleSignIn

class UserIdentityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userID: UILabel!
    
    var emailIsThere = false // checks if email has already been found.
    var tableViewTitles = ["Friends", "Email Preferences", "Privacy Settings"]
    var friends: [String] = []
    
    var signInObserver: AnyObject!
    var signOutObserver: AnyObject!
    var willEnterForegroundObserver: AnyObject!
    fileprivate let loginButton: UIBarButtonItem = UIBarButtonItem(title: nil, style: .done, target: nil, action: nil)
    
    // MARK: - View lifecycle
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        
        presentSignInViewController()
        
        // Facebook Email
        if let token = FBSDKAccessToken.current()
        {
            let parameters = ["fields":"email, friends"]
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: parameters)
            
            _ = graphRequest?.start { [weak self] connection, result, error in
                // If something went wrong, we're logged out
                if (error != nil)
                {
                    print("Error: \(error)")
                }
                
                // Transform to dictionary first
                if let result = result as? [String: Any]
                {
                    var emailExists = true
                    // Got the email
                    guard let email = result["email"] as? String else
                    {
                        print("No email")
                        emailExists = false
                        return
                    }
                    if emailExists
                    {
                        self!.emailIsThere = true
                        self!.userID.text = email
                    }
                    if let f = result["friends"] as? [String: Any]
                    {
                        if let arr = f["data"] as? NSArray
                        {
                            for i in 0...(arr.count - 1)
                            {
                                if let entry = arr[i] as? [String: Any]
                                {
                                    if let name = entry["name"] as? String
                                    {
                                        if self!.friends.contains(name)
                                        {
                                            continue
                                        }
                                        self!.friends.append(name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        
        // Google Email
        if GIDSignIn.sharedInstance().clientID != nil
        {
            let user = GIDSignIn.sharedInstance().currentUser
            if let profile = user?.profile
            {
                if let email = profile.email
                {
                    self.userID.text = email
                    self.friends = []
                }
            }
        }
        
        let identityManager = AWSIdentityManager.default()
        
        if let identityUserName = identityManager.userName
        {
            userName.text = identityUserName
        }
        else
        {
            userName.text = NSLocalizedString("Guest User", comment: "Placeholder text for the guest user.")
        }
        
        if let imageURL = identityManager.imageURL
        {
            let imageData = try! Data(contentsOf: imageURL)
            if let profileImage = UIImage(data: imageData)
            {
                userImageView.image = profileImage
//                userImageView.layer.masksToBounds = false
//                userImageView.layer.cornerRadius = userImageView.frame.height/1.5
//                userImageView.clipsToBounds = true
            }
            else
            {
                userImageView.image = UIImage(named: "UserIcon")
            }
        }
        
        signInObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AWSIdentityManagerDidSignIn, object: AWSIdentityManager.default(), queue: OperationQueue.main, using: {[weak self] (note: Notification) -> Void in
            guard let strongSelf = self else { return }
            print("Sign In Observer observed sign in.")
            strongSelf.setupRightBarButtonItem()
            // You need to call `updateTheme` here in case the sign-in happens after `- viewWillAppear:` is called.
            //                        strongSelf.updateTheme()
        })
        
        signOutObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AWSIdentityManagerDidSignOut, object: AWSIdentityManager.default(), queue: OperationQueue.main, using: {[weak self](note: Notification) -> Void in
            guard let strongSelf = self else { return }
            print("Sign Out Observer observed sign out.")
            strongSelf.setupRightBarButtonItem()
            //                        strongSelf.updateTheme()
        })
        
        setupRightBarButtonItem()
        
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(signInObserver)
        NotificationCenter.default.removeObserver(signOutObserver)
        NotificationCenter.default.removeObserver(willEnterForegroundObserver)
    }
    
    func setupRightBarButtonItem()
    {
        navigationItem.rightBarButtonItem = loginButton
        navigationItem.rightBarButtonItem!.target = self
        
        if (AWSIdentityManager.default().isLoggedIn)
        {
            navigationItem.rightBarButtonItem!.title = NSLocalizedString("Sign-Out", comment: "Label for the logout button.")
            navigationItem.rightBarButtonItem!.action = #selector(MainViewController.handleLogout)
        }
    }
    
    func presentSignInViewController()
    {
        if !AWSIdentityManager.default().isLoggedIn
        {
            let storyboard = UIStoryboard(name: "SignIn", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "SignIn")
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    func handleLogout()
    {
        if (AWSIdentityManager.default().isLoggedIn)
        {
            //            ColorThemeSettings.sharedInstance.wipe()
            AWSIdentityManager.default().logout(completionHandler: {(result: Any?, error: Error?) in
                self.navigationController!.popToRootViewController(animated: false)
                self.setupRightBarButtonItem()
                self.presentSignInViewController()
            })
            // print("Logout Successful: \(signInProvider.getDisplayName)");
        }
        else
        {
            assert(false)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return tableViewTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell()
        cell.textLabel?.text = tableViewTitles[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if indexPath.row == 0
        {
           performSegue(withIdentifier: "friendsSegue", sender: friends)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let friendsVC = segue.destination as! FriendsViewController
        friendsVC.friendsArray = sender as! Array
    }
}
