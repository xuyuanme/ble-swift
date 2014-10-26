//
//  CentralManager.swift
//  ble-swift
//
//  Created by Yuan on 14-10-24.
//  Copyright (c) 2014年 xuyuanme. All rights reserved.
//

import Foundation
import CoreBluetooth

var thisCentralManager : CentralManager?

public class CentralManager : NSObject, CBCentralManagerDelegate {
    
    private let cbCentralManager : CBCentralManager!
    private let centralQueue = dispatch_queue_create("me.xuyuan.ble", DISPATCH_QUEUE_SERIAL)
    
    public class func sharedInstance() -> CentralManager {
        if thisCentralManager == nil {
            thisCentralManager = CentralManager()
        }
        return thisCentralManager!
    }
    
    // MARK: Private
    private override init() {
        Logger.debug("Initialize Central Manager")
        super.init()
        self.cbCentralManager = CBCentralManager(delegate:self, queue:self.centralQueue, options:[CBCentralManagerOptionRestoreIdentifierKey:"mainCentralManagerIdentifier"])
    }
    
    // MARK: CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_:CBCentralManager!) {
    }
    
    public func centralManager(_:CBCentralManager!, didDiscoverPeripheral peripheral:CBPeripheral!, advertisementData:NSDictionary!, RSSI:NSNumber!) {
    }
    
    public func centralManager(_:CBCentralManager!, didConnectPeripheral peripheral:CBPeripheral!) {
    }
    
    public func centralManager(_:CBCentralManager!, didFailToConnectPeripheral peripheral:CBPeripheral!, error:NSError!) {
    }
    
    public func centralManager(_:CBCentralManager!, didDisconnectPeripheral peripheral:CBPeripheral!, error:NSError!) {
    }

    public func centralManager(_:CBCentralManager!, didRetrieveConnectedPeripherals peripherals:[AnyObject]!) {
    }
    
    public func centralManager(_:CBCentralManager!, didRetrievePeripherals peripherals:[AnyObject]!) {
    }
    
    public func centralManager(_:CBCentralManager!, willRestoreState dict:NSDictionary!) {
        Utils.sendNotification("CBCentralManager willRestoreState", soundName: "")
    }

}