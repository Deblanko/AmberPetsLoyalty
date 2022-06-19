//
//  UserInfoViewController.swift
//  AmberPetsLoyalty
//
//  Created by Paul Branton on 01/06/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import UIKit
import os.log

class UserInfoViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var lastSeenTextField: UITextField!
    
    var userId : String = ""
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let customer = DataModel.sharedInstance.customers[userId] {
            nameTextField.text = customer.displayName
            emailTextField.text = customer.email
            lastSeenTextField.text = customer.prettyDate
        }
        
    }
    
}
