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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.view.roundButtons()
        
//        self.dataObserver = dataModel.observe(\.customerTableData, changeHandler: { (theModel, chnage) in
//            self.tableView.reloadData()
//        })
  
    }
    
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.dataObserver = dataModel.observe(\.lastRefresh, changeHandler: { (theModel, change) in
            os_log("Customer View, updating", log: OSLog.customerView, type: .info)
            self.tableView.reloadData()
        })

        if let user = Auth.auth().currentUser {
            //os_log("User uid-> %@", log: OSLog.initialView, type: .info, String(describing:user.uid))
            dataModel.customerQRData = CustomerQRData(type: user.providerID, userId: user.uid)
            if let theCode = dataModel.base64StringFromCustomerData() {
                if let qrImage = UIImage.generateQrCode(theCode) {
                    self.customerQRCodeImageView.image = qrImage
                    let smallLogo = UIImage(named: "SmallLogo")
                    smallLogo?.addToCenter(of: self.customerQRCodeImageView, width: 60, height: 60)
                }
            }
            
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dataObserver?.invalidate()
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
        try? Auth.auth().signOut()
        if let vc = self.tabBarController as? InitialViewController {
            vc.showLogin()
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
