//
//  PeripheralController.swift
//  ble-swift
//
//  Created by Yuan on 14/11/1.
//  Copyright (c) 2014年 xuyuanme. All rights reserved.
//

import Foundation
import CoreBluetooth

public class Peripheral : NSObject, CBPeripheralDelegate {
    
    // INTERNAL
    internal let cbPeripheral    : CBPeripheral!
    
    // PUBLIC
    public let advertisements  : Dictionary<NSObject, AnyObject>!
    public let rssi            : Int!
    
    public var name : String {
        if let name = cbPeripheral.name {
            return name
        } else {
            return "Unknown"
        }
    }
    
    public var state : CBPeripheralState {
        return self.cbPeripheral.state
    }
    
    public var identifier : NSUUID! {
        return self.cbPeripheral.identifier
    }
    
    public init(cbPeripheral:CBPeripheral, advertisements:Dictionary<NSObject, AnyObject>, rssi:Int) {
        super.init()
        self.cbPeripheral = cbPeripheral
        self.cbPeripheral.delegate = self
        self.advertisements = advertisements
        self.rssi = rssi
    }
    
}