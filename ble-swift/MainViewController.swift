//
//  MainViewController.swift
//  ble-swift
//
//  Created by Yuan on 14-10-20.
//  Copyright (c) 2014年 xuyuanme. All rights reserved.
//

import UIKit
import CoreBluetooth

class MainViewController: UIViewController, SelectPeripheralProtocol, ConnectPeripheralProtocol, ReadPeripheralProtocol {
    
    @IBOutlet weak var connectBarButton: UIBarButtonItem!
    @IBOutlet weak var wheelValueLabel: UILabel!
    
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
    func didSelectPeripheral(peripheral:Peripheral) {
        Logger.debug("MainViewController#didPeripheralSelected \(peripheral.name)")
        selectedPeripheral.removeAll(keepCapacity: false)
        selectedPeripheral[peripheral.cbPeripheral] = peripheral
        CentralManager.sharedInstance().connectPeripheral(peripheral)
        dispatch_async(dispatch_get_main_queue(), {
            self.isPeripheralConnected = true
            self.title = "Connecting..."
            self.connectBarButton.title = "Disconnect"
        })
    }
    
    // MARK: ConnectPeripheralProtocol
    func didConnectPeripheral(cbPeripheral: CBPeripheral!) {
        Logger.debug("MainViewController#didConnectPeripheral \(cbPeripheral.name)")
        dispatch_async(dispatch_get_main_queue(), {
            self.title = cbPeripheral.name
        })
        // Start to read data
        if let peripheral = self.selectedPeripheral[cbPeripheral] {
            peripheral.discoverServices([CBUUID(string: serviceUUIDString)], delegate: self)
        }
    }
    
    func didDisconnectPeripheral(cbPeripheral: CBPeripheral!, error: NSError!, userClickedCancel: Bool) {
        Logger.debug("MainViewController#didDisconnectPeripheral \(cbPeripheral.name)")
        let peripheral = self.selectedPeripheral[cbPeripheral]
        if (!userClickedCancel && peripheral != nil) {
            Logger.debug("Unexpected disconnect, try auto reconnect...")
            CentralManager.sharedInstance().connectPeripheral(peripheral!)
            dispatch_async(dispatch_get_main_queue(), {
                self.title = "Reconnecting..."
            })
        } else {
            Logger.debug("User clicked disconnect")
            dispatch_async(dispatch_get_main_queue(), {
                self.isPeripheralConnected = false
                self.title = ""
                self.connectBarButton.title = "Connect"
                self.wheelValueLabel.text = "0"
            })
        }
    }
    
    func didRestorePeripheral(peripheral:Peripheral) {
        self.didSelectPeripheral(peripheral)
    }
    
    // MARK: ReadPeripheralProtocol for CSC (Cycling Speed and Cadence)
    var serviceUUIDString:String = "1816"
    var characteristicUUIDString:String = "2A5B"
    
    var wheelFlag:UInt8 = 0x01
    var crankFlag:UInt8 = 0x02
    
    func didUpdateValueForCharacteristic(characteristic: CBCharacteristic!, error: NSError!) {
        var flags:UInt8 = 0
        var wheelRevolutions:UInt32 = 0
        var lastWheelEventTime:UInt16 = 0
        var crankRevolutions:UInt16 = 0
        var lastCrankEventTime:UInt16 = 0
        
        var data = characteristic.value
        data.getBytes(&flags, range: NSRange(location: 0, length: 1))
        
        if (flags & wheelFlag == wheelFlag) {
            data.getBytes(&wheelRevolutions, range: NSRange(location: 1, length: 4))
            data.getBytes(&lastWheelEventTime, range: NSRange(location: 5, length: 2))
            data.getBytes(&crankRevolutions, range: NSRange(location: 7, length: 2))
            data.getBytes(&lastCrankEventTime, range: NSRange(location: 9, length: 2))
        } else if (flags & crankFlag == crankFlag) {
            data.getBytes(&crankRevolutions, range: NSRange(location: 1, length: 2))
            data.getBytes(&lastCrankEventTime, range: NSRange(location: 3, length: 2))
        }
        
        Logger.debug("\(wheelRevolutions)")
        
        dispatch_async(dispatch_get_main_queue(), {
            self.wheelValueLabel.text = String(wheelRevolutions)
        })
    }

}
