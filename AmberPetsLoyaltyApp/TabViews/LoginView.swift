//
//  LoginView.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 23/08/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import SwiftUI

import Firebase
import FirebaseAuthUI
import FirebaseOAuthUI
import FirebaseEmailAuthUI

import os.log

struct LoginView: View {
    @State var vm : DataModel

    var body: some View {
        CustomLoginViewController() { user, error in
                // output error
            let _ = print("Error \(String(describing:error?.localizedDescription))")
            if let user = user {
                vm.addUser(userId: user.uid, displayName: user.displayName, email: user.email)
                vm.loginState = .loggedIn
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DataModel()
        LoginView(vm:vm)
    }
}

struct CustomLoginViewController : UIViewControllerRepresentable {
    var dismiss : (_ user: User?, _ error : Error? ) -> Void
    
    func makeCoordinator() -> CustomLoginViewController.Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let authUI = FUIAuth.defaultAuthUI()
        
        let providers : [FUIAuthProvider] = [
            FUIEmailAuth(),
            FUIOAuth.appleAuthProvider()
        ]
        
        authUI?.providers = providers
        authUI?.delegate = context.coordinator
        authUI?.shouldHideCancelButton = true
        
        let authViewController = authUI?.authViewController()
        
        return authViewController!
    }
 
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<CustomLoginViewController>) {

    }
    
    //coordinator
    class Coordinator : NSObject, FUIAuthDelegate {
        
        let log = OSLog(subsystem: OSLogger.subsystem, category: "Login")
        
        var parent : CustomLoginViewController
        
        init(_ customLoginViewController : CustomLoginViewController) {
            self.parent = customLoginViewController
        }
        
        // MARK: FUIAuthDelegate
        func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
            if let error = error {
                parent.dismiss(nil,error)
            }
            else {
                // login will be set in the StateDidChangeListener
                if let user = authDataResult?.user  {
                    os_log("User displayName-> %@", log: self.log, type: .info, String(describing:user.displayName))
                    os_log("User phoneNumber-> %@", log: self.log, type: .info, String(describing:user.phoneNumber))
                    os_log("User uid-> %@", log: self.log, type: .info, String(describing:user.uid))
                    os_log("User photoURL-> %@", log: self.log, type: .info, String(describing:user.photoURL))
                    os_log("User providerID-> %@", log: self.log, type: .info, String(describing:user.providerID))
                    os_log("User tenantID-> %@", log: self.log, type: .info, String(describing:user.tenantID))
                    os_log("User email-> %@", log: self.log, type: .info, String(describing:user.email))
                    parent.dismiss(user,nil)
                }
                else {
                    os_log("Logged in without a user?", log: self.log, type: .error)
                    parent.dismiss(nil,nil) //???
                }

                
            }
        }
        
        func authUI(_ authUI: FUIAuth, didFinish operation: FUIAccountSettingsOperationType, error: Error?) {
            os_log("didFinish", log: self.log, type: .info)
        }
    }
}
