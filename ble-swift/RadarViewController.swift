//
//  RadarViewController.swift
//  ble-swift
//
//  Created by Yuan on 15/4/3.
//  Copyright (c) 2015年 xuyuanme. All rights reserved.
//

import UIKit
import CoreBluetooth

class RadarViewController: UIViewController {

    @IBOutlet weak var rssiLabel: UILabel!
    var peripheral : Peripheral?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.title = peripheral?.name
        CentralManager.sharedInstance().stopScanning()
        CentralManager.sharedInstance().startScanning(afterPeripheralDiscovered, allowDuplicatesKey: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        CentralManager.sharedInstance().stopScanning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func afterPeripheralDiscovered(cbPeripheral:CBPeripheral, advertisementData:NSDictionary, RSSI:NSNumber) {
        if (peripheral?.cbPeripheral == cbPeripheral) {
            // Bypass 127. The disconnected case will be handled by other logic
            if (RSSI != 127) { // 127 means disconnected, which sometimes is not true
                dispatch_async(dispatch_get_main_queue()) {
                    self.rssiLabel.text = RSSI.stringValue
                }
            }
        }
    }

}
