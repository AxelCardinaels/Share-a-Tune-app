//
//  FeedViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 11/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration

class FeedViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //On affiche la bar de navigation
        self.navigationController?.navigationBarHidden = false;

        
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
