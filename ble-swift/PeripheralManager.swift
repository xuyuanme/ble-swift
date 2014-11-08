//
//  PeripheralManager.swift
//  ble-swift
//
//  Created by Yuan on 14/11/8.
//  Copyright (c) 2014年 xuyuanme. All rights reserved.
//

import Foundation
import CoreBluetooth

var thisPeripheralManager : PeripheralManager?

protocol CreatePeripheralProtocol {
    var serviceUUIDString:String {get}
    var characteristicUUIDString:String {get}
    func didReceiveReadRequest(peripheralManager:CBPeripheralManager!, didReceiveReadRequest request:CBATTRequest!)
}

public class PeripheralManager : NSObject, CBPeripheralManagerDelegate {
    var createPeripheralDelegate:CreatePeripheralProtocol!
    private let peripheralQueue = dispatch_queue_create("me.xuyuan.ble.peripheral.main", DISPATCH_QUEUE_SERIAL)
    internal var cbPeripheralManager : CBPeripheralManager!
    
    // MARK: Singleton
    public class func sharedInstance() -> PeripheralManager {
        if thisPeripheralManager == nil {
            thisPeripheralManager = PeripheralManager()
        }
        return thisPeripheralManager!
    }
    
    private override init() {
        Logger.debug("PeripheralManager#init")
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:self.peripheralQueue, options:[CBPeripheralManagerOptionRestoreIdentifierKey:"mainPeripheralManagerIdentifier"])
    }
    
    // MARK: Public
    // advertising
    public func startAdvertising() {
        Logger.debug("PeripheralManager#startAdvertising")
        var advertisementData : [NSObject:AnyObject] = [CBAdvertisementDataServiceUUIDsKey : [CBUUID(string: self.createPeripheralDelegate.serviceUUIDString)]]
        self.cbPeripheralManager.startAdvertising(advertisementData)
    }
    
    public func stopAdvertising(afterAdvertisingStopped:(()->())? = nil) {
        Logger.debug("PeripheralManager#stopAdvertising")
        self.cbPeripheralManager.stopAdvertising()
    }
    
    // MARK: CBPeripheralManagerDelegate
    public func peripheralManagerDidUpdateState(peripheral:CBPeripheralManager!) {
        switch peripheral.state {
        case CBPeripheralManagerState.PoweredOn:
            Logger.debug("PeripheralManager#peripheralManagerDidUpdateState: poweredOn")
            self.cbPeripheralManager.addService(self.createPeripheralService())
            self.startAdvertising()
            break
        case CBPeripheralManagerState.PoweredOff:
            Logger.debug("PeripheralManager#peripheralManagerDidUpdateState: poweredOff")
            break
        case CBPeripheralManagerState.Resetting:
            break
        case CBPeripheralManagerState.Unsupported:
            break
        case CBPeripheralManagerState.Unauthorized:
            break
        case CBPeripheralManagerState.Unknown:
            break
        }
    }
    
    public func peripheralManager(_:CBPeripheralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        if let services:[CBMutableService] = dict[CBPeripheralManagerRestoredStateServicesKey] as [CBMutableService]! {
            Logger.debug("PeripheralManager#willRestoreState")
        }
    }
    
    public func peripheralManagerDidStartAdvertising(_:CBPeripheralManager!, error:NSError!) {
        if error == nil {
            Logger.debug("PeripheralManager#peripheralManagerDidStartAdvertising: Success")
        } else {
            Logger.debug("PeripheralManager#peripheralManagerDidStartAdvertising: Failed '\(error.localizedDescription)'")
        }
    }
    
    public func peripheralManager(_:CBPeripheralManager!, didAddService service:CBService!, error:NSError!) {
        if error == nil {
            Logger.debug("PeripheralManager#didAddService: Success")
        } else {
            Logger.debug("PeripheralManager#didAddService: Failed '\(error.localizedDescription)'")
        }
    }
    
    public func peripheralManager(_:CBPeripheralManager!, central:CBCentral!, didSubscribeToCharacteristic characteristic:CBCharacteristic!) {
        Logger.debug("PeripheralManager#didSubscribeToCharacteristic")
    }
    
    public func peripheralManager(_:CBPeripheralManager!, central:CBCentral!, didUnsubscribeFromCharacteristic characteristic:CBCharacteristic!) {
        Logger.debug("PeripheralManager#didUnsubscribeFromCharacteristic")
    }
    
    public func peripheralManagerIsReadyToUpdateSubscribers(_:CBPeripheralManager!) {
        Logger.debug("PeripheralManager#peripheralManagerIsReadyToUpdateSubscribers")
    }
    
    public func peripheralManager(peripheralManager:CBPeripheralManager!, didReceiveReadRequest request:CBATTRequest!) {
        Logger.debug("PeripheralManager#didReceiveReadRequest: chracteracteristic \(request.characteristic.UUID)")
        self.createPeripheralDelegate.didReceiveReadRequest(peripheralManager, didReceiveReadRequest: request)
    }
    
    public func peripheralManager(peripheralManager:CBPeripheralManager!, didReceiveWriteRequests requests:[AnyObject]!) {
        Logger.debug("PeripheralManager#didReceiveWriteRequests")
    }
    
    // MARK: private
    private func createPeripheralService() -> CBMutableService {
        var characteristic = CBMutableCharacteristic(type: CBUUID(string: self.createPeripheralDelegate.characteristicUUIDString), properties:CBCharacteristicProperties.Read, value:nil, permissions:CBAttributePermissions.Readable)
        var service = CBMutableService(type: CBUUID(string: self.createPeripheralDelegate.serviceUUIDString), primary: true)
        service.characteristics = [characteristic]
        return service
    }
    
}