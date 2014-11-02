//
//  MainViewController.swift
//  ble-swift
//
//  Created by Yuan on 14-10-20.
//  Copyright (c) 2014年 xuyuanme. All rights reserved.
//

import UIKit
import CoreBluetooth

class MainViewController: UIViewController, SelectPeripheralProtocol, ConnectPeripheralProtocol {
    
    @IBOutlet weak var connectBarButton: UIBarButtonItem!
    
    var selectedPeripheral : Dictionary<CBPeripheral, Peripheral> = [:]
    var isPeripheralConnected:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        CentralManager.sharedInstance().connectPeripheralDelegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Controller logic
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if(segue.identifier == "SelectPeripheral") {
            var controller:SelectPeripheralViewController = segue.destinationViewController as SelectPeripheralViewController
            controller.delegate = self
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String?, sender:AnyObject?) -> Bool {
        if(identifier == "SelectPeripheral") {
            if (self.isPeripheralConnected) {
                if let peripheral = self.selectedPeripheral.values.array.first {
                    CentralManager.sharedInstance().cancelPeripheralConnection(peripheral, userClickedCancel: true)
                    return false
                }
            }
        }
        return true
    }
    
    @IBAction func testButtonClicked(sender: AnyObject) {
        Logger.debug("testButtonClicked")
        // Utils.sendNotification("testButtonClicked", soundName: "")
        kill(getpid(), SIGKILL)
    }

    // MARK: SelectPeripheralProtocol
    func didPeripheralSelected(peripheral:Peripheral) {
        Logger.debug("MainViewController#didPeripheralSelected \(peripheral.name)")
        selectedPeripheral.removeAll(keepCapacity: false)
        selectedPeripheral[peripheral.cbPeripheral] = peripheral
        CentralManager.sharedInstance().connectPeripheral(peripheral)
    }
    
    // MARK: ConnectPeripheralProtocol
    func didConnectPeripheral(cbPeripheral: CBPeripheral!) {
        Logger.debug("MainViewController#didConnectPeripheral \(cbPeripheral.name)")
        dispatch_async(dispatch_get_main_queue(), {
            self.isPeripheralConnected = true
            self.title = cbPeripheral.name
            self.connectBarButton.title = "Disconnect"
        })
    }
    
    func didDisconnectPeripheral(cbPeripheral: CBPeripheral!, error: NSError!, userClickedCancel: Bool) {
        Logger.debug("MainViewController#didDisconnectPeripheral \(cbPeripheral.name)")
        let peripheral = self.selectedPeripheral[cbPeripheral]
        if (!userClickedCancel && peripheral != nil) {
            Logger.debug("Unexpected disconnect, try auto reconnect...")
            CentralManager.sharedInstance().connectPeripheral(peripheral!)
        } else {
            Logger.debug("User clicked disconnect")
            dispatch_async(dispatch_get_main_queue(), {
                self.isPeripheralConnected = false
                self.title = ""
                self.connectBarButton.title = "Connect"
            })
        }
    }

}
