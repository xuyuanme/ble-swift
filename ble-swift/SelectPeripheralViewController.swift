//
//  SelectPeripheralViewController.swift
//  ble-swift
//
//  Created by Yuan on 14-10-26.
//  Copyright (c) 2014年 xuyuanme. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol SelectPeripheralProtocol {
    func didPeripheralSelected(peripheral:Peripheral)
}

class SelectPeripheralViewController: UITableViewController {
    var delegate:SelectPeripheralProtocol!
    var discoveredPeripherals : Dictionary<CBPeripheral, Peripheral> = [:]
    var tempPeripherals : Dictionary<CBPeripheral, Peripheral> = [:]
    var allowDuplicatesKey : Bool = true
    
    private var timer:NSTimer!

    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        CentralManager.sharedInstance().startScanning(afterPeripheralDiscovered, allowDuplicatesKey: allowDuplicatesKey)
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("refreshPeripherals"), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        CentralManager.sharedInstance().stopScanning()
        timer.invalidate()
        timer = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.discoveredPeripherals.values.array.count
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PeripheralCell", forIndexPath: indexPath) as UITableViewCell
        let peripheral = self.discoveredPeripherals.values.array[indexPath.row]
        cell.textLabel.text = peripheral.name
        return cell
    }
    
    // MARK: UITableViewDelegate
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        self.navigationController?.popViewControllerAnimated(true)
        self.delegate.didPeripheralSelected(discoveredPeripherals.values.array[indexPath.row])
    }
    
    // MARK: Private
    private func afterPeripheralDiscovered(cbPeripheral:CBPeripheral, advertisementData:NSDictionary, RSSI:NSNumber) {
        if (self.tempPeripherals[cbPeripheral] == nil) {
            let peripheral = Peripheral(cbPeripheral:cbPeripheral, advertisements:advertisementData, rssi:RSSI.integerValue)
            // Logger.debug("SelectPeripheralViewController#afterPeripheralDiscovered: Store peripheral \(peripheral.name)")
            self.tempPeripherals[cbPeripheral] = peripheral
        } else {
            // Logger.debug("SelectPeripheralViewController#afterPeripheralDiscovered: Already stored peripheral \(cbPeripheral.name)")
        }
    }
    
    // Not used
    private func unpackAdvertisements(advertDictionary:NSDictionary!) -> Dictionary<String,String> {
        Logger.debug("SelectPeripheralViewController#unpackAdvertisements found \(advertDictionary.count) advertisements")
        var advertisements = Dictionary<String, String>()
        func addKey(key:String, andValue value:AnyObject) -> () {
            if value is NSString {
                advertisements[key] = (value as? String)
            } else if value is CBUUID {
                advertisements[key] = value.UUIDString
            } else {
                advertisements[key] = value.stringValue
            }
            Logger.debug("SelectPeripheralViewController#unpackAdvertisements key:\(key), value:\(advertisements[key])")
        }
        if advertDictionary != nil {
            for keyObject : AnyObject in advertDictionary.allKeys {
                let key = keyObject as String
                let value : AnyObject! = advertDictionary.objectForKey(keyObject)
                if value is NSArray {
                    for v : AnyObject in (value as NSArray) {
                        // TODO: Bug, duplicate key will be overrided
                        addKey(key, andValue:v)
                    }
                } else {
                    addKey(key, andValue:value)
                }
            }
        }
        Logger.debug("SelectPeripheralViewController#unpackAdvertisements unpacked \(advertisements.count) advertisements")
        return advertisements
    }
    
    func refreshPeripherals() {
        discoveredPeripherals = tempPeripherals // Copy by value
        if (allowDuplicatesKey) {
            // Empty and restart collecting
            tempPeripherals = [:]
        }
        dispatch_async(dispatch_get_main_queue(), self.tableView.reloadData)
    }

}
