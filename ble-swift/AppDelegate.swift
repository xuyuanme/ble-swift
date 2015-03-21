//
//  AppDelegate.swift
//  ble-swift
//
//  Created by Yuan on 14-10-20.
//  Copyright (c) 2014年 xuyuanme. All rights reserved.
//

import UIKit
import CoreLocation
import Parse
import CoreBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, UIAlertViewDelegate, CreatePeripheralProtocol, ConnectPeripheralProtocol, ReadPeripheralProtocol {

    var window: UIWindow?
    var locationManager: CLLocationManager!
    
    var serviceUUIDString:String = ""
    var characteristicUUIDString:String = ""
    
    var selectedPeripheral : Dictionary<CBPeripheral, Peripheral> = [:]

    // MARK: UIApplicationDelegate
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
            if var localNotification: UILocalNotification = options[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
                // User click local notification to launch app
                // Need to handle the local notification here
                Utils.showAlert("didFinishLaunchingWithOptions \(localNotification.alertBody!)")
            }
            if var remoteNotification: NSDictionary = options[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
                // Awake from remote notification
                // No further logic here, will be handled by application didReceiveRemoteNotification fetchCompletionHandler
                Utils.sendNotification("Awake from remote notification", soundName: "")
            }
            if var booleanFlag: NSNumber = options[UIApplicationLaunchOptionsLocationKey] as? NSNumber {
                // Awake from location
                // No further logic here, will be handled by locationManager didUpdateLocations
                Utils.sendNotification("Awake from location", soundName: "")
            }
            if var centralManagerIdentifiers: NSArray = options[UIApplicationLaunchOptionsBluetoothCentralsKey] as? NSArray {
                // Awake as Bluetooth Central
                // No further logic here, will be handled by centralManager willRestoreState
                Utils.sendNotification("Awake as Bluetooth Central", soundName: "")
            }
            if var peripheralManagerIdentifiers: NSArray = options[UIApplicationLaunchOptionsBluetoothPeripheralsKey] as? NSArray {
                // Awake as Bluetooth Peripheral
                // No further logic here, will be handled by peripheralManager willRestoreState
                Utils.sendNotification("Awake as Bluetooth Peripheral", soundName: "")
            }
        }

        // Initialize the Location Manager
        initLocationManager()
        
        initParse()
        
        initBluetooth()

        return true
    }
    
    func initLocationManager() {
        if (nil == locationManager) {
            Logger.debug("Initialize Location Manager")
            locationManager = CLLocationManager()
        }
        locationManager.delegate = self
        if (locationManager.respondsToSelector(Selector("requestAlwaysAuthorization"))) {
            Logger.debug("requestAlwaysAuthorization for iOS8")
            
            var status:CLAuthorizationStatus = CLLocationManager.authorizationStatus()
            
            if (status == CLAuthorizationStatus.Denied || status == CLAuthorizationStatus.AuthorizedWhenInUse) {
                var alert = UIAlertView(title: status == CLAuthorizationStatus.Denied ? "Location services are off" : "Background location is not enabled", message: "To use background location you must turn on 'Always' in the Location Services Settings", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Settings")
                alert.show()
            } else if (status == CLAuthorizationStatus.NotDetermined) {
                locationManager.requestAlwaysAuthorization()
            }
        }
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func initParse() {
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("Keys", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            Parse.setApplicationId(dict["ApplicationId"] as String, clientKey: dict["ClientKey"] as String)
        }
    }
    
    func initBluetooth() {
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("Keys", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            self.serviceUUIDString = dict["ServiceUUIDString"] as String
            self.characteristicUUIDString = dict["NameCharacteristicUUIDString"] as String
        }
        
        CentralManager.sharedInstance().connectPeripheralDelegate = self
        PeripheralManager.sharedInstance().createPeripheralDelegate = self
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        var characterSet: NSCharacterSet = NSCharacterSet(charactersInString: "<>")
        var deviceTokenString: String = (deviceToken.description as NSString)
            .stringByTrimmingCharactersInSet( characterSet)
            .stringByReplacingOccurrencesOfString(" ", withString: "") as String
        
        Logger.debug("didRegisterForRemoteNotificationsWithDeviceToken \(deviceTokenString)")
        
        var currentInstallation = PFInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        if(PFUser.currentUser() != nil) {
            currentInstallation["user"] = PFUser.currentUser()
        }
        currentInstallation.saveInBackgroundWithBlock(nil)
    }
    
    func application(application: UIApplication!, didFailToRegisterForRemoteNotificationsWithError error: NSError!) {
        Logger.debug("didFailToRegisterForRemoteNotificationsWithError \(error.localizedDescription)")
    }
    
    func application(application: UIApplication, didReceiveLocalNotification localNotification:UILocalNotification) {
        // Receive local notification in the foreground
        // Or user click local notification to switch to foreground
        Logger.debug("didReceiveLocalNotification "+localNotification.alertBody!)
        // Utils.showAlert("didReceiveLocalNotification \(localNotification.alertBody!)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        var notification:NSDictionary = userInfo["aps"] as NSDictionary
        var alert:String = notification.objectForKey("alert") as String
        
        if (application.applicationState == UIApplicationState.Active || application.applicationState == UIApplicationState.Inactive) {
            // If the value is Inactive, the user tapped an action button; if the value is Active, the app was frontmost when it received the notification
            Utils.showAlert("didReceiveRemoteNotification \(application.applicationState.rawValue.description) \(alert)")
            application.applicationIconBadgeNumber = 0
        } else {
            // Background or Not Running
            Logger.debug(notification)
        }
        
        if(application.applicationState == UIApplicationState.Inactive) {
            // The application was just brought from the background to the foreground,
            // so we consider the app as having been "opened by a push notification."
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayloadInBackground(userInfo, block: nil);
        }
    }

    func application(application: UIApplication!, didReceiveRemoteNotification userInfo:[NSObject : AnyObject], fetchCompletionHandler handler:(UIBackgroundFetchResult) -> Void) {
        self.application(application, didReceiveRemoteNotification: userInfo)
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
    
    // MARK: CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [CLLocation]!) {
        Logger.debug("Updated locations: \(locations)")
        Utils.sendNotification("\(locations)", soundName: "")
    }
    
    // MARK: UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if (buttonIndex == 1) {
            var settingURL = NSURL(string: UIApplicationOpenSettingsURLString)
            UIApplication.sharedApplication().openURL(settingURL!)
        }
    }
    
    // MARK: CreatePeripheralProtocol
    func didReceiveReadRequest(peripheralManager: CBPeripheralManager!, didReceiveReadRequest request: CBATTRequest!) {
        if(request.characteristic.UUID.UUIDString == self.characteristicUUIDString) {
            var result = "unknown"
            if(PFUser.currentUser() != nil) {
                result = PFUser.currentUser().username
            }
            request.value = NSData(data: result.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)
            peripheralManager.respondToRequest(request, withResult: CBATTError.Success)
        }
    }
    
    // MARK: ConnectPeripheralProtocol
    func didConnectPeripheral(cbPeripheral: CBPeripheral!) {
        Logger.debug("AppDelegate#didConnectPeripheral \(cbPeripheral.name)")
        if let peripheral = self.selectedPeripheral[cbPeripheral] {
            peripheral.discoverServices([CBUUID(string: serviceUUIDString)], delegate: self)
        }
    }
    
    func didDisconnectPeripheral(cbPeripheral: CBPeripheral!, error: NSError!, userClickedCancel: Bool) {
        Logger.debug("AppDelegate#didDisconnectPeripheral \(cbPeripheral.name)")
    }
    
    func didRestorePeripheral(peripheral: Peripheral) {
        Logger.debug("AppDelegate#didRestorePeripheral \(peripheral.name)")
    }
    
    func bluetoothBecomeAvailable() {
        CentralManager.sharedInstance().startScanning(afterPeripheralDiscovered, allowDuplicatesKey: false)
    }
    
    func bluetoothBecomeUnavailable() {
        CentralManager.sharedInstance().stopScanning()
    }
    
    // MARK: ReadPeripheralProtocol
    func didUpdateValueForCharacteristic(cbPeripheral: CBPeripheral!, characteristic: CBCharacteristic!, error: NSError!) {
        if let data = characteristic.value {
            if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                Logger.debug("AppDelegate#didUpdateValueForCharacteristic \(result)")
                if(result != "unknown" && PFUser.currentUser() != nil) {
                    Utils.sendNotification("\(NSString(data: data, encoding: NSUTF8StringEncoding))", soundName: "")
                }
            }
        }
        if let peripheral = self.selectedPeripheral[cbPeripheral] {
            CentralManager.sharedInstance().cancelPeripheralConnection(peripheral, userClickedCancel: true);
        }
    }
    
    // MARK: Private
    private func afterPeripheralDiscovered(cbPeripheral:CBPeripheral, advertisementData:NSDictionary, RSSI:NSNumber) {
        let peripheral = Peripheral(cbPeripheral:cbPeripheral, advertisements:advertisementData, rssi:RSSI.integerValue)
        Logger.debug("AppDelegate#afterPeripheralDiscovered: Connect peripheral \(peripheral.name)")
        CentralManager.sharedInstance().connectPeripheral(peripheral)
        selectedPeripheral[peripheral.cbPeripheral] = peripheral
    }

}
