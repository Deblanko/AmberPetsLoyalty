//
//  RedeemedTableViewController.swift
//  AmberPetsLoyalty
//
//  Created by Admin on 9/25/20.
//  Copyright © 2020 Deblanko. All rights reserved.
//

import UIKit

class RedeemedTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // TEST
        let user1 = "EXBFhJiJoAZ8JfY0OmuCOZ3XrHy1"
        let x1 = Redeemed(userId: user1, date: "2020-10-01T14:33:14.550Z")
        let x2 = Redeemed(userId: user1, date: "2020-09-30T14:33:14.550Z")
        let x3 = Redeemed(userId: user1, date: "2020-08-23T14:33:14.550Z")
        let x4 = Redeemed(userId: user1, date: "2020-07-12T14:33:14.550Z")
        let x5 = Redeemed(userId: user1, date: "2020-06-11T14:33:14.550Z")
        let x6 = Redeemed(userId: user1, date: "2020-05-05T14:33:14.550Z")
        let x7 = Redeemed(userId: user1, date: "2020-04-23T14:33:14.550Z")
        let x8 = Redeemed(userId: user1, date: "2020-03-28T14:33:14.550Z")
        let x9 = Redeemed(userId: user1, date: "2020-02-29T14:33:14.550Z")
        DataModel.sharedInstance.redeemed.append(x1)
        DataModel.sharedInstance.redeemed.append(x2)
        DataModel.sharedInstance.redeemed.append(x3)
        DataModel.sharedInstance.redeemed.append(x4)
        DataModel.sharedInstance.redeemed.append(x5)
        DataModel.sharedInstance.redeemed.append(x6)
        DataModel.sharedInstance.redeemed.append(x7)
        DataModel.sharedInstance.redeemed.append(x8)
        DataModel.sharedInstance.redeemed.append(x9)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DataModel.sharedInstance.buildRedeemedTable()
        self.tableView.reloadData()
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
