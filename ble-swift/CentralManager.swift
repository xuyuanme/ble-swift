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
    var serviceUUIDString:String {get}
    func didConnectPeripheral(cbPeripheral:CBPeripheral!)
    func didDisconnectPeripheral(cbPeripheral:CBPeripheral!, error:NSError!, userClickedCancel:Bool)
    func didRestorePeripheral(peripheral:Peripheral)
}

public class CentralManager : NSObject, CBCentralManagerDelegate {
    let STORED_PERIPHERAL_IDENTIFIER = "STORED_PERIPHERAL_IDENTIFIER"
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
            Logger.debug("CentralManager#startScanningForServiceUUIDs: \(uuids) allowDuplicatesKey: \(allowDuplicatesKey)")
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
        if (userClickedCancel) {
            var userDefaults = NSUserDefaults.standardUserDefaults()
            userDefaults.setObject(nil, forKey: STORED_PERIPHERAL_IDENTIFIER)
            userDefaults.synchronize()
        }
    }

    // MARK: CBCentralManagerDelegate
    public func centralManagerDidUpdateState(central:CBCentralManager!) {
        var statusText:String
        
        switch central.state {
        case CBCentralManagerState.PoweredOn:
            statusText = "Bluetooth powered on."
            var userDefaults = NSUserDefaults.standardUserDefaults()
            var peripheralUUID = userDefaults.stringForKey(STORED_PERIPHERAL_IDENTIFIER)
            if (peripheralUUID != nil) {
                Logger.debug("CentralManager#retrievePeripheralsWithIdentifiers \(peripheralUUID)")
                Utils.sendNotification("CentralManager#retrievePeripheralsWithIdentifiers \(peripheralUUID)", soundName: "")
                for p:AnyObject in central.retrievePeripheralsWithIdentifiers([CBUUID(string: peripheralUUID)]) {
                    if p is CBPeripheral {
                        peripheralFound(p as CBPeripheral)
                        return
                    }
                }
                Logger.debug("CentralManager#retrieveConnectedPeripheralsWithServices")
                for p:AnyObject in central.retrieveConnectedPeripheralsWithServices([CBUUID(string: self.connectPeripheralDelegate.serviceUUIDString)]) {
                    if p is CBPeripheral {
                        peripheralFound(p as CBPeripheral)
                        return
                    }
                }
            }
        case CBCentralManagerState.PoweredOff:
            statusText = "Bluetooth powered off."
        case CBCentralManagerState.Unsupported:
            statusText = "Bluetooth low energy hardware not supported."
        case CBCentralManagerState.Unauthorized:
            statusText = "Bluetooth unauthorized state."
        case CBCentralManagerState.Unknown:
            statusText = "Bluetooth unknown state."
        default:
            statusText = "Bluetooth unknown state."
        }
        
        Logger.debug("CentralManager#centralManagerDidUpdateState: \(statusText)")
    }
    
    public func centralManager(_:CBCentralManager!, didDiscoverPeripheral cbPeripheral:CBPeripheral!, advertisementData:NSDictionary!, RSSI:NSNumber!) {
        // Logger.debug("CentralManager#didDiscoverPeripheral \(cbPeripheral.name)")
        if let afterPeripheralDiscovered = self.afterPeripheralDiscovered {
            afterPeripheralDiscovered(cbPeripheral:cbPeripheral, advertisementData:advertisementData, RSSI:RSSI)
        }
    }
    
    public func centralManager(_:CBCentralManager!, didConnectPeripheral peripheral:CBPeripheral!) {
        Logger.debug("CentralManager#didConnectPeripheral")
        
        var userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(peripheral.identifier.UUIDString as String, forKey: STORED_PERIPHERAL_IDENTIFIER)
        userDefaults.synchronize()
        
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
        userClickedCancel = false
    }

    public func centralManager(_:CBCentralManager!, didRetrieveConnectedPeripherals peripherals:[AnyObject]!) {
        Logger.debug("CentralManager#didRetrieveConnectedPeripherals")
    }
    
    public func centralManager(_:CBCentralManager!, didRetrievePeripherals peripherals:[AnyObject]!) {
        Logger.debug("CentralManager#didRetrievePeripherals")
    }
    
    public func centralManager(_:CBCentralManager!, willRestoreState dict:NSDictionary!) {
        if let peripherals:[CBPeripheral] = dict[CBCentralManagerRestoredStatePeripheralsKey] as [CBPeripheral]! {
            Logger.debug("CentralManager#willRestoreState")
        }
    }

    // MARK: Private
    private func peripheralFound(cbPeripheral: CBPeripheral) {
        Logger.debug("CentralManager#peripheralFound \(cbPeripheral.name)")
        var peripheral:Peripheral = Peripheral(cbPeripheral: cbPeripheral, advertisements:[:], rssi:0)
        self.connectPeripheralDelegate.didRestorePeripheral(peripheral)
    }

}