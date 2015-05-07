//
//  SignUpFirstViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 7/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit

class SignUpFirstViewController: UIViewController {
    
    @IBOutlet var boutonPhoto: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = false;
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        
        boutonPhoto.layer.cornerRadius = 0.5 * boutonPhoto.bounds.size.width
        
        // Do any additional setup after loading the view.
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
    
}
