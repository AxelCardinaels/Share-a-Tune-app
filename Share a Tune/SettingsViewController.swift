//
//  SettingsViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 26/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration

class SettingsViewController: UIViewController, UITableViewDelegate {
    
    var settingsContainer = ["Se déconnecter","Visiter le site de Share a Tune"]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.setHidesBackButton(true, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1;
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return settingsContainer.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("classicCell", forIndexPath: indexPath) as! UITableViewCell;
        
        cell.textLabel!.text = settingsContainer[indexPath.row]
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        let indexPath = tableView.indexPathForSelectedRow();
        
        let currentCell = tableView.cellForRowAtIndexPath(indexPath!)
        var cellTitle = currentCell?.textLabel!.text
        
        if cellTitle! == "Se déconnecter" {
            PFUser.logOut()
            var currentUser = PFUser.currentUser()
            performSegueWithIdentifier("logout", sender: self)
            
        }else{
            UIApplication.sharedApplication().openURL(NSURL(string: "http://www.axelcardinaels.be/shareatuneapp")!)
        }
        
    }

}
