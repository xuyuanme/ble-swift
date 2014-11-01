//
//  SelectPeripheralViewController.swift
//  ble-swift
//
//  Created by Yuan on 14-10-26.
//  Copyright (c) 2014年 xuyuanme. All rights reserved.
//

import UIKit

protocol SelectPeripheralProtocol {
    func didPeripheralSelected(indexPath:NSIndexPath)
}

class SelectPeripheralViewController: UITableViewController {
    var delegate:SelectPeripheralProtocol!

    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return 3
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PeripheralCell", forIndexPath: indexPath) as UITableViewCell
        cell.textLabel.text = "\(indexPath.row)"
        return cell
    }
    
    // MARK: UITableViewDelegate
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        self.navigationController?.popViewControllerAnimated(true)
        self.delegate.didPeripheralSelected(indexPath)
    }

}
