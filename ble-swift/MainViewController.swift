//
//  MainViewController.swift
//  ble-swift
//
//  Created by Yuan on 14-10-20.
//  Copyright (c) 2014年 xuyuanme. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, SelectPeripheralProtocol {
    
    @IBOutlet weak var connectBarButton: UIBarButtonItem!
    
    var isPeripheralConnected:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if(segue.identifier == "SelectPeripheral") {
            var controller:SelectPeripheralViewController = segue.destinationViewController as SelectPeripheralViewController
            controller.delegate = self
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String?, sender:AnyObject?) -> Bool {
        if(identifier == "SelectPeripheral") {
            if (self.isPeripheralConnected) {
                disconnect()
                return false
            }
        }
        return true
    }
    
    // MARK: Controller logic
    @IBAction func testButtonClicked(sender: AnyObject) {
        Logger.debug("testButtonClicked")
//        Utils.sendNotification("testButtonClicked", soundName: "")
        kill(getpid(), SIGKILL)
    }
    
    func connect() {
        self.isPeripheralConnected = true
        self.connectBarButton.title = "Disconnect"
    }
    
    func disconnect() {
        self.isPeripheralConnected = false
        self.connectBarButton.title = "Connect"
    }
    
    // MARK: SelectPeripheralProtocol
    func didPeripheralSelected(peripheral:Peripheral) {
        Logger.debug("\(peripheral.name)")
        self.connect()
    }

}
