//
//  FirstViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 13/06/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if NSUserDefaults.standardUserDefaults().boolForKey("HasLaunchedOnce") != false{
            self.performSegueWithIdentifier("AlreadyLaunched", sender: self)
            
            
        }else{
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunchedOnce")
            NSUserDefaults.standardUserDefaults().synchronize()
            
        }
    }
    
    
    
}
