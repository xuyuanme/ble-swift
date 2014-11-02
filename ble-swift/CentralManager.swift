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

protocol ConnectPeripheralProtocol {
    func didConnectPeripheral(cbPeripheral:CBPeripheral!)
    func didDisconnectPeripheral(cbPeripheral:CBPeripheral!, error:NSError!, userClickedCancel:Bool)
}

public class CentralManager : NSObject, CBCentralManagerDelegate {
    var connectPeripheralDelegate : ConnectPeripheralProtocol!
    
    private let cbCentralManager : CBCentralManager!
    private let centralQueue = dispatch_queue_create("me.xuyuan.ble", DISPATCH_QUEUE_SERIAL)
    private var _isScanning = false
    private var userClickedCancel = false
    private var afterPeripheralDiscovered : ((cbPeripheral:CBPeripheral, advertisementData:NSDictionary, RSSI:NSNumber)->())?

    // MARK: Singleton
    public class func sharedInstance() -> CentralManager {
        if thisCentralManager == nil {
            thisCentralManager = CentralManager()
        }
        return thisCentralManager!
    }
    
    private override init() {
        Logger.debug("CentralManager#init")
        super.init()
        self.cbCentralManager = CBCentralManager(delegate:self, queue:self.centralQueue, options:[CBCentralManagerOptionRestoreIdentifierKey:"mainCentralManagerIdentifier"])
    }
    
    // MARK: Public
    // scanning
    public func startScanning(afterPeripheralDiscovered:(cbPeripheral:CBPeripheral, advertisementData:NSDictionary, RSSI:NSNumber)->(), allowDuplicatesKey:Bool) {
        self.startScanningForServiceUUIDs(nil, afterPeripheralDiscovered: afterPeripheralDiscovered, allowDuplicatesKey: allowDuplicatesKey)
    }
    
    public func startScanningForServiceUUIDs(uuids:[CBUUID]!, afterPeripheralDiscovered:(cbPeripheral:CBPeripheral, advertisementData:NSDictionary, RSSI:NSNumber)->(), allowDuplicatesKey:Bool) {
        if !self._isScanning {
            Logger.debug("CentralManager#startScanningForServiceUUIDs: \(uuids)")
            self._isScanning = true
            self.afterPeripheralDiscovered = afterPeripheralDiscovered
            self.cbCentralManager.scanForPeripheralsWithServices(uuids,options: [CBCentralManagerScanOptionAllowDuplicatesKey: allowDuplicatesKey])
        }
    }
    
    public func stopScanning() {
        if self._isScanning {
            Logger.debug("CentralManager#stopScanning")
            self._isScanning = false
            self.cbCentralManager.stopScan()
        }
    }
    
    // connection
    public func connectPeripheral(peripheral:Peripheral) {
        Logger.debug("CentralManager#connectPeripheral")
        self.cbCentralManager.connectPeripheral(peripheral.cbPeripheral, options : [
            CBCentralManagerOptionShowPowerAlertKey : true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey : true,
            CBConnectPeripheralOptionNotifyOnNotificationKey : true])
    }
    
    public func cancelPeripheralConnection(peripheral:Peripheral, userClickedCancel:Bool) {
        Logger.debug("CentralManager#cancelPeripheralConnection")
        self.cbCentralManager.cancelPeripheralConnection(peripheral.cbPeripheral)
        self.userClickedCancel = userClickedCancel
    }

    // MARK: CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_:CBCentralManager!) {
        Logger.debug("CentralManager#centralManagerDidUpdateState: \(self.cbCentralManager.state)")
    }
    
    public func centralManager(_:CBCentralManager!, didDiscoverPeripheral cbPeripheral:CBPeripheral!, advertisementData:NSDictionary!, RSSI:NSNumber!) {
        // Logger.debug("CentralManager#didDiscoverPeripheral \(cbPeripheral.name)")
        if let afterPeripheralDiscovered = self.afterPeripheralDiscovered {
            afterPeripheralDiscovered(cbPeripheral:cbPeripheral, advertisementData:advertisementData, RSSI:RSSI)
        }
    }
    
    public func centralManager(_:CBCentralManager!, didConnectPeripheral peripheral:CBPeripheral!) {
        Logger.debug("CentralManager#didConnectPeripheral")
        if let connectPeripheralDelegate = self.connectPeripheralDelegate {
            connectPeripheralDelegate.didConnectPeripheral(peripheral)
        }
    }
    
    public func centralManager(_:CBCentralManager!, didFailToConnectPeripheral peripheral:CBPeripheral!, error:NSError!) {
        Logger.debug("CentralManager#didFailToConnectPeripheral")
    }
    
    public func centralManager(_:CBCentralManager!, didDisconnectPeripheral peripheral:CBPeripheral!, error:NSError!) {
        Logger.debug("CentralManager#didDisconnectPeripheral")
        if let connectPeripheralDelegate = self.connectPeripheralDelegate {
            connectPeripheralDelegate.didDisconnectPeripheral(peripheral, error: error, userClickedCancel: userClickedCancel)
        }
    }

    public func centralManager(_:CBCentralManager!, didRetrieveConnectedPeripherals peripherals:[AnyObject]!) {
        Logger.debug("CentralManager#didRetrieveConnectedPeripherals")
    }
    
    public func centralManager(_:CBCentralManager!, didRetrievePeripherals peripherals:[AnyObject]!) {
        Logger.debug("CentralManager#didRetrievePeripherals")
    }
    
    public func centralManager(_:CBCentralManager!, willRestoreState dict:NSDictionary!) {
        Logger.debug("CentralManager#willRestoreState")
        Utils.sendNotification("CBCentralManager willRestoreState", soundName: "")
    }

}