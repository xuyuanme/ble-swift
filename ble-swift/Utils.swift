//
//  Utils.swift
//  ble-swift
//
//  Created by Yuan on 14-10-20.
//  Copyright (c) 2014年 xuyuanme. All rights reserved.
//

import Foundation
import UIKit

class Utils {
    
    class func sendNotification(note:String, soundName:String) {
        var notification = UILocalNotification()
        notification.fireDate = NSDate(timeIntervalSinceNow: 7)
        notification.hasAction = false
        notification.alertBody = note
        notification.timeZone = NSTimeZone.defaultTimeZone()
        notification.soundName = soundName
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    class func showAlert(message:String) {
        var alert = UIAlertView()
        alert.title = "Notification"
        alert.message = message
        alert.addButtonWithTitle("OK")
        alert.show()
    }
    
}