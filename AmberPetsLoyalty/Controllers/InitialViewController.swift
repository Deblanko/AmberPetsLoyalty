//
//  InitialViewController.swift
//  AmberPetsLoyalty
//
//  Created by Admin on 9/15/20.
//  Copyright © 2020 Deblanko. All rights reserved.
//

import UIKit
import os.log
import Firebase
import FirebaseUI


class InitialViewController: UITabBarController {

    //let db = Firestore.firestore()
    
    var isAdminObserver : NSKeyValueObservation?
    var loggedInObserver : NSKeyValueObservation?
    var dataModel = DataModel.sharedInstance
    
    let tabBarNames = [
        "adminVC" : "person.crop.circle.fill.badge.plus",
        "usersNavVC" : "rectangle.stack.person.crop.fill",
        "redeemedVC" : "sterlingsign.circle.fill"
    ]
    
    //var handle: AuthStateDidChangeListenerHandle?

    lazy var adminVCs: [String: UIViewController] = {
        var vcs = [String: UIViewController]()
        for name in Array(tabBarNames.keys) {
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: name) {
                if let imageName = self.tabBarNames[name] {
                    if #available(iOS 13.0, *) {
                        vc.tabBarItem.image = UIImage(systemName: imageName)
                    } else {
                        // Fallback on earlier versions
                    }
                }
                vcs[name] = vc
                
                
            }
        }
        return vcs
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()


        isAdminObserver = dataModel.observe(\.isAdmin, changeHandler: { (theModel, change) in
            let customerVC = self.viewControllers?.first{$0 as? CustomerViewController != nil }
            self.viewControllers = []
            if let customerVC = customerVC ?? self.storyboard?.instantiateViewController(withIdentifier: "customerVC") {
                if theModel.isAdmin {
                    if let adminVC = self.adminVCs["adminVC"],
                        let usersVC = self.adminVCs["usersNavVC"],
                        let redeemVC = self.adminVCs["redeemedVC"] {
                        self.viewControllers = [adminVC, usersVC, redeemVC, customerVC]
                        self.tabBar.isHidden = false
                    }
                }
                else {
                    self.viewControllers = [customerVC]
                    self.tabBar.isHidden = true
                }
            }
        })
        
        loggedInObserver = dataModel.observe(\.loggedIn, changeHandler: { (theModel, change) in
            
            if !theModel.loggedIn {
                self.showLogin()
            }
        })

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
//        if Auth.auth().currentUser != nil {
//            // User is signed in.
//            // ...
//
//            if let user = Auth.auth().currentUser {
//                os_log("User uid-> %@", log: OSLog.initialView, type: .info, String(describing:user.uid))
//                checkAdminState(email: user.email)
//                DataModel.sharedInstance.addUser(userId: user.uid, displayName: user.displayName, email: user.email)
//            }
//
//        } else {
//            // No user is signed in.
//            // ...
////            self.showLogin()
//
//
//        }
    }
    
    public func showLogin() {
        os_log("showLogin", log: OSLog.initialView, type: .info)
        
        if let authUI = FUIAuth.defaultAuthUI() {
            authUI.delegate = self
            
//            var actionCodeSettings = ActionCodeSettings()
//            actionCodeSettings.url = URL(string: "amber-pets-loyalty.firebaseapp.com")
//            actionCodeSettings.handleCodeInApp = true
//            //actionCodeSettings.setAndroidPackageName("com.firebase.example", installIfNotAvailable: false, minimumVersion: "12")
//
//
//            let provider = FUIEmailAuth(authUI: authUI,
//                                        signInMethod: FIREmailLinkAuthSignInMethod,
//                                        forceSameDevice: true,
//                                        allowNewEmailAccounts: true,
//                                        actionCodeSetting: actionCodeSettings)
            // Setup login provider ( Need to import these seperately )
            if #available(iOS 13.0, *) {
                authUI.providers = [  FUIEmailAuth(), FUIFacebookAuth(), FUIOAuth.appleAuthProvider() ]
            } else {
                // Fallback on earlier versions
                authUI.providers = [ FUIEmailAuth(), FUIFacebookAuth() ]
            }
            authUI.shouldAutoUpgradeAnonymousUsers = true
            authUI.shouldHideCancelButton = true
            let authViewController = authUI.authViewController()
            present(authViewController, animated: true, completion: {})
        }
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
//    func checkAdminState(email:String?) {
//        if let email = email {
//            db.collection("admins").whereField("email", isEqualTo: email).getDocuments() { (querySnapshot, err) in
//                    if let err = err {
//                        print("Error getting documents: \(err)")
//                    } else {
//                        DataModel.sharedInstance.isAdmin = (querySnapshot?.documents.count ?? 0) > 0
//                    }
//            }
//        }
//    }

    
}

extension InitialViewController : FUIAuthDelegate {
    
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        // handle user and error as necessary
        
        if let user = user  {
            os_log("User displayName-> %@", log: OSLog.initialView, type: .info, String(describing:user.displayName))
            os_log("User phoneNumber-> %@", log: OSLog.initialView, type: .info, String(describing:user.phoneNumber))
            os_log("User uid-> %@", log: OSLog.initialView, type: .info, String(describing:user.uid))
            os_log("User photoURL-> %@", log: OSLog.initialView, type: .info, String(describing:user.photoURL))
            os_log("User providerID-> %@", log: OSLog.initialView, type: .info, String(describing:user.providerID))
            os_log("User tenantID-> %@", log: OSLog.initialView, type: .info, String(describing:user.tenantID))
 //           checkAdminState(email: user.email)
            DataModel.sharedInstance.addUser(userId: user.uid, displayName: user.displayName, email: user.email)
        }
    }
}
