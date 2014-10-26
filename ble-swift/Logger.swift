//
//  Logger.swift
//  ble-swift
//
//  Created by Yuan on 14-10-24.
//  Copyright (c) 2014年 xuyuanme. All rights reserved.
//

import Foundation

public class Logger {
    
    public class func debug(message:AnyObject) {
        #if DEBUG
            println("\(message)")
        #endif
    }
    
}