//
//  NearbyTableViewController.swift
//  ble-swift
//
//  Created by Yuan on 15/3/26.
//  Copyright (c) 2015年 xuyuanme. All rights reserved.
//

import UIKit
import CoreBluetooth

class NearbyTableViewController: UITableViewController {
    var nearbyPeripherals : [Peripheral] = []
    var historyPeripherals : [Peripheral] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTable:", name: "afterPeripheralDiscovered", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTable:", name: "didUpdateValueForCharacteristic", object: nil)
        var appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        appDelegate.stopScanning()
        appDelegate.startScanning()
        self.updateData()
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if (section == 0) {
            return nearbyPeripherals.count
        } else {
            return historyPeripherals.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NearbyCell", forIndexPath: indexPath) as UITableViewCell
        var peripheral:Peripheral
        if (indexPath.section == 0) {
            peripheral = nearbyPeripherals[indexPath.row]
        } else {
            peripheral = historyPeripherals[indexPath.row]
        }
        cell.textLabel?.text = peripheral.name
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Nearby"
        } else {
            return "History"
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        let path = self.tableView.indexPathForSelectedRow()!
        let vc : RadarViewController = segue.destinationViewController as RadarViewController
        if (path.section == 0) {
            vc.peripheral = nearbyPeripherals[path.row]
        } else {
            vc.peripheral = historyPeripherals[path.row]
        }
    }
    
    // MARK: - Private
    func refreshTable(notification: NSNotification) {
        Logger.debug("NearbyTableViewController#refreshTable for \(notification.name) notification")
        self.updateData()
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    private func updateData() {
        nearbyPeripherals.removeAll(keepCapacity: true)
        historyPeripherals.removeAll(keepCapacity: true)
        var appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        for peripheral:Peripheral in appDelegate.discoveredPeripherals.values.array {
            if (peripheral.isNearby) {
                nearbyPeripherals.append(peripheral)
            } else {
                historyPeripherals.append(peripheral)
            }
        }
    }

}
