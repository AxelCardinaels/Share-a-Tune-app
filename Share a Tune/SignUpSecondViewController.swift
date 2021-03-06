//
//  SignUpSecondViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 7/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration

class SignUpSecondViewController: UIViewController, UITextFieldDelegate {
    
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    @IBOutlet var prenom: UITextField!
    @IBOutlet var nom: UITextField!
    @IBOutlet var erreurBar: UILabel!
    @IBOutlet var senderButton: UIButton!
    @IBAction func signUpName(sender: AnyObject) {
        
        var error="";
        var searchTerm = ""
        var termCount = NSInteger()
        
        if prenom.text == "" || nom.text == "" {
            error = "empty"
        }else{
            
            
            searchTerm = prenom!.text
            termCount = count(searchTerm)
            
            let regex = NSRegularExpression(pattern: ".*[^A-Za-z\\s\\-].*", options: nil, error: nil)!
            if regex.firstMatchInString(searchTerm, options: nil, range: NSMakeRange(0, termCount)) != nil {
                error = "noSpec"
                
            }else{
                searchTerm = nom!.text
                termCount = count(searchTerm)
                
                let regex = NSRegularExpression(pattern: ".*[^A-Za-z\\s\\-].*", options: nil, error: nil)!
                if regex.firstMatchInString(searchTerm, options: nil, range: NSMakeRange(0, termCount)) != nil {
                    error = "noSpec"
                    
                }
            }
        }
        
        if isConnectedToNetwork() == false{
            error="noInternet"
        }
        
        
        if error != ""{
            
            showError(self,error,erreurBar )
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
            
        }else{
            
            var currentUser = PFUser.currentUser()
            if currentUser != nil {
                currentUser?["prenom"] = prenom.text
                currentUser?["nom"] = nom.text
                currentUser?["bio"] = "noBio"
                
                activityIndicatorButtonMake(senderButton)
                view.addSubview(activityIndicatorButton)
                currentUser?.saveInBackground()
                activityIndicatorButtonKill(senderButton)
                
                self.performSegueWithIdentifier("signUpDone", sender: self)
                
            } else {
                error = "error"
            }
            
        }
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.prenom.delegate = self;
        self.nom.delegate = self;
        
        prenom.layer.borderWidth = 0.85
        prenom.layer.borderColor = UIColor(red: 203/255, green: 20/255, blue: 102/255, alpha: 0.8).CGColor
        nom.layer.borderWidth = 0.85
        nom.layer.borderColor = UIColor(red: 203/255, green: 20/255, blue: 102/255, alpha: 0.8).CGColor
        
        
        self.navigationItem.hidesBackButton = true;
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true);
    }
    
    func textFieldShouldReturn(textField : UITextField ) -> Bool{
        textField.resignFirstResponder()
        return true
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
