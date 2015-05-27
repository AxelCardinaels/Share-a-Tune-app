//
//  LoginViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 6/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    @IBOutlet var username: UITextField!
    
    @IBOutlet var password: UITextField!
    
    @IBOutlet var erreurBar: UILabel!
    
    @IBOutlet var senderButton: UIButton!
    
    
    @IBAction func login(sender: AnyObject) {
        
        
        var error="";
        var currentUser = PFUser.currentUser()
        currentUser?.fetch()
        
        
        if username.text == "" || password.text == "" {
            error = "empty"
            
        }else{
            
            
            
            if currentUser?.objectForKey("emailVerified")?.boolValue == false{
                error = "noVerif"
            }
        }
        
        if isConnectedToNetwork() == false{
            error="noInternet"
        }
        
        
        if error != ""{
            
            showError(self,error,erreurBar)
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
            
        }else{
            
            activityIndicatorButtonMake(senderButton)
            view.addSubview(activityIndicatorButton)
            
            var lowerUsername = username.text.lowercaseString
            
            PFUser.logInWithUsernameInBackground(lowerUsername, password: password.text!) {
                (user: PFUser?, errorLogin: NSError?) -> Void in
                
                activityButtonText = self.senderButton.titleLabel!.text!
                activityIndicatorButtonKill(self.senderButton)
                
                if user != nil {
                    self.performSegueWithIdentifier("isLogged", sender: self)
                    
                } else {
                    
                    if let errorLogin = errorLogin{
                        let errorString = errorLogin.userInfo?["error"] as? NSString
                        // Show the errorString somewhere and let the user try again.
                        
                        error = errorString as! String
                        var errortest: AnyObject? = errorLogin.userInfo?["code"]
                        errortest = toString(errortest!)
                        
                        showError(self, errortest as! String, self.erreurBar)
                        var timer = NSTimer()
                        timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
        username.attributedPlaceholder = NSAttributedString(string:"Votre nom d'utilisateur",
            attributes:[NSForegroundColorAttributeName: UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)])
        
        password.attributedPlaceholder = NSAttributedString(string:"Votre mot de passe",
            attributes:[NSForegroundColorAttributeName: UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)])
        
        self.username.delegate = self;
        self.password.delegate = self;
        
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        if PFUser.currentUser() != nil {
            self.performSegueWithIdentifier("isLogged", sender: self)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
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
