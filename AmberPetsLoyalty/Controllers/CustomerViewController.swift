//
//  CustomerViewController.swift
//  AmberPetsLoyalty
//
//  Created by Admin on 9/18/20.
//  Copyright © 2020 Deblanko. All rights reserved.
//

import UIKit
import Firebase
import os.log


class CustomerViewController: UIViewController {

    @IBOutlet weak var customerQRCodeImageView: UIImageView!
    
    @IBOutlet weak var tableView: UITableView!
    let dataModel = DataModel.sharedInstance
    var dataObserver : NSKeyValueObservation?
    var loginObserver : NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.view.roundButtons()
        
        self.customerQRCodeImageView.layer.magnificationFilter = .nearest
        
  
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.dataObserver = dataModel.observe(\.lastRefresh, changeHandler: { (theModel, change) in
            os_log("Customer View, updating", log: OSLog.customerView, type: .info)
            self.tableView.reloadData()
        })
        self.loginObserver = dataModel.observe(\.loggedIn, changeHandler: { (theModel, chnage) in
            self.loginUpdated()
        })
        loginUpdated()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dataObserver?.invalidate()
        self.loginObserver?.invalidate()
    }
    
    func loginUpdated() {
        if let theCode = dataModel.base64StringFromCustomerData() {
            if let qrImage = UIImage.generateQrCode(theCode) {
                self.customerQRCodeImageView.image = qrImage
                let smallLogo = UIImage(named: "SmallLogo")
                smallLogo?.addToCenter(of: self.customerQRCodeImageView, width: 60, height: 60)
            }
        }
        else {
            self.customerQRCodeImageView.image = nil
        }
        
//        self.tableView.reloadData()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func logoutButtonClick(_ sender: UIButton) {
        dataModel.logout()        
    }
    
    @IBAction func renameButtonClick(_ sender: UIButton) {
        if let loggedInUser = dataModel.loggedInUserId {
            let oldName = dataModel.userTable().first?.details ?? "N/A"
            let alert = UIAlertController(title: "Rename", message: "Old Name:\(oldName)", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "New Name"
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                if let name = alert.textFields?.first?.text {
                    self.dataModel.updateUser(userId: loggedInUser, displayName: name)
                }
            }))
            self.present(alert, animated: true) {
                //
            }
        }
    }
    
}

extension CustomerViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = dataModel.userTable().count
        os_log("Number of rows in section %d = %d", log: OSLog.customerView, type: .info, section, count)
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
        let datum = dataModel.userTable()[indexPath.row]
        
        cell.textLabel?.text = datum.title
        cell.detailTextLabel?.text = datum.details
        
        return cell
    }
    
    
    
}
