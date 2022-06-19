//
//  UserTableViewController.swift
//  AmberPetsLoyalty
//
//  Created by Admin on 9/25/20.
//  Copyright © 2020 Deblanko. All rights reserved.
//

import UIKit
import os.log

class UserTableViewController: UITableViewController {
    
    let dataModel = DataModel.sharedInstance
    var dataObserver : NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.view.roundButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dataObserver = dataModel.observe(\.lastRefresh, changeHandler: { (theModel, change) in
            os_log("All customers View, updating", log: OSLog.allCustomersView, type: .info)
            self.tableView.reloadData()
        })
        self.tableView.reloadData()

    
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dataObserver?.invalidate()
        self.dataObserver = nil
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataModel.sharedInstance.customers.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        
        // Configure the cell...
        let keys = Array(DataModel.sharedInstance.customers.keys)
        let userId = keys[indexPath.row] as String
        let customer = DataModel.sharedInstance.customers[userId]
        cell.textLabel?.text = customer?.displayName ?? "N/A"

        var value = "N/A"
        if let points = customer?.getPoints(userId: userId) {
            value = "\(points)"
        }
        cell.detailTextLabel?.text = value

        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        let keys = Array(dataModel.customers.keys)

        if let cell = sender as? UITableViewCell {
            let buttonPosition:CGPoint = cell.convert(CGPoint.zero, to: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: buttonPosition), let vc = segue.destination as? UserInfoViewController {
                vc.userId = keys[indexPath.row] as String
                return
            }
        }
        
        guard let selectedRow = tableView.indexPathForSelectedRow else {
            return
        }
        
        let userId = keys[selectedRow.row] as String
        if let vc = segue.destination as? UserDetailsViewController {
             vc.selectedUserId = userId
        }
    }
    
//    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
//
//    }
}
