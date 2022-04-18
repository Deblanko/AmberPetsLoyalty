//
//  UserDetailsViewController.swift
//  AmberPetsLoyalty
//
//  Created by Paul Branton on 16/04/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import UIKit
import os.log

class UserDetailsViewController: UITableViewController {
    let dataModel = DataModel.sharedInstance
    var dataObserver : NSKeyValueObservation?
    var selectedUserId : String? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dataObserver = dataModel.observe(\.lastRefresh, changeHandler: { (theModel, change) in
            os_log("Vouchers (Redeemed) View, updating", log: OSLog.vouchersView, type: .info)
            self.dataModel.buildRedeemedTable(selectedUserId: self.selectedUserId)
            self.tableView.reloadData()
        })
        dataModel.buildRedeemedTable(selectedUserId: selectedUserId)
        self.tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dataObserver?.invalidate()
        self.dataObserver = nil
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return DataModel.sharedInstance.redeemedTableData.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = DataModel.sharedInstance.redeemedTableData[section].count
        return count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title = DataModel.sharedInstance.redeemedTableSections[section]
        return title
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "redeemedCell", for: indexPath)

        // Configure the cell...
        let section = DataModel.sharedInstance.redeemedTableData[indexPath.section]
        let redeemedData = section[indexPath.row]
        cell.textLabel?.text = redeemedData.displayName
        cell.detailTextLabel?.text = redeemedData.date

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


}
