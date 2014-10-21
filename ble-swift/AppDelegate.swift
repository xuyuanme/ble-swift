//
//  AppDelegate.swift
//  ble-swift
//
//  Created by Yuan on 14-10-20.
//  Copyright (c) 2014年 xuyuanme. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        if (application.respondsToSelector(Selector("registerUserNotificationSettings:"))) {
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Sound | UIUserNotificationType.Alert |
                UIUserNotificationType.Badge, categories: nil))
            application.registerForRemoteNotifications()
        } else {
            application.registerForRemoteNotificationTypes(UIRemoteNotificationType.Badge | UIRemoteNotificationType.Sound | UIRemoteNotificationType.Alert)
        }
        
        if var options = launchOptions {
            // User click local notification to launch app
            if var localNotification: UILocalNotification = options[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
                Utils.showAlert("didFinishLaunchingWithOptions \(localNotification.alertBody!)")
            }
        }

        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        var characterSet: NSCharacterSet = NSCharacterSet(charactersInString: "<>")
        var deviceTokenString: String = (deviceToken.description as NSString)
            .stringByTrimmingCharactersInSet( characterSet)
            .stringByReplacingOccurrencesOfString(" ", withString: "") as String
        
        println("didRegisterForRemoteNotificationsWithDeviceToken \(deviceTokenString)")
    }
    
    func application(application: UIApplication!, didFailToRegisterForRemoteNotificationsWithError error: NSError!) {
        println("didFailToRegisterForRemoteNotificationsWithError \(error.localizedDescription)")
    }
    
    func application(application: UIApplication, didReceiveLocalNotification localNotification:UILocalNotification) {
        // Receive local notification in the foreground
        // Or user click local notification to switch to foreground
        println("didReceiveLocalNotification "+localNotification.alertBody!)
        Utils.showAlert("didReceiveLocalNotification \(localNotification.alertBody!)")
    }

    func application(application: UIApplication!, didReceiveRemoteNotification remoteNotification:NSDictionary!, fetchCompletionHandler handler:(UIBackgroundFetchResult) -> Void) {
        var notification:NSDictionary = remoteNotification.objectForKey("aps") as NSDictionary
        var alert:String = notification.objectForKey("alert") as String
        
        if (application.applicationState == UIApplicationState.Active || application.applicationState == UIApplicationState.Inactive) {
            // If the value is Inactive, the user tapped an action button; if the value is Active, the app was frontmost when it received the notification
            Utils.showAlert("didReceiveRemoteNotification \(application.applicationState.rawValue.description) \(alert)")
            application.applicationIconBadgeNumber = 0
        } else {
            // Background or Not Running
            println(notification)
        }

        handler(UIBackgroundFetchResult.NewData)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}
