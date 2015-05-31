//
//  SignUpFirstViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 7/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration

class SignUpFirstViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate{
    
    //-------------- Gestion des erreurs -----------------//
    
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    //-------------- Gestion de l'inscription -----------------//
    
    
    @IBOutlet var boutonPhoto: UIButton!
    @IBOutlet var email: UITextField!
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var erreurBar: UILabel!
    @IBOutlet var senderButton: UIButton!
    var profilPicture = UIImageView(image: UIImage(named: "noopf.png"))
    
    //Inscription
    @IBAction func signUp(sender: AnyObject) {
        
        var error="";
        var mdpCount = NSInteger()
        var searchTerm = ""
        var termCount = NSInteger()
        
        if username.text == "" || password.text == "" || email.text == "" {
            error = "empty"
        }else{
            mdpCount = count(password!.text)
            searchTerm = username!.text
            termCount = count(searchTerm)
            
            if termCount < 3{
                error="shortUsername"
            }else{
                
                let regex = NSRegularExpression(pattern: ".*[^A-Za-z0-9\\-\\.\\_].*", options: nil, error: nil)!
                if regex.firstMatchInString(searchTerm, options: nil, range: NSMakeRange(0, termCount)) != nil {
                    error = "noSpecUser"
                }else{
                    if mdpCount < 5{
                        error="shortPassword"
                    }
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
            
            var imageData = UIImagePNGRepresentation(self.profilPicture.image)
            var imageFile = PFFile(name:"ProfilPicture", data: imageData)
            
            var emailText = email.text!
            var emailLower = emailText.lowercaseString
            var usernameLower = username.text.lowercaseString
            var user = PFUser()
            user.email = emailLower
            user.username = usernameLower
            user.password = password.text!
            user["profilePicture"] = imageFile
            
            activityIndicatorButtonMake(senderButton)
            view.addSubview(activityIndicatorButton)
            
            
            user.signUpInBackgroundWithBlock {
                (succeeded: Bool, errorSignUp: NSError?) -> Void in
                
                activityButtonText = self.senderButton.titleLabel!.text!
                activityIndicatorButtonKill(self.senderButton)
                
                if let errorSignUp = errorSignUp {
                    let errorString = errorSignUp.userInfo?["error"] as? NSString
                    // Show the errorString somewhere and let the user try again.
                    
                    error = errorString as! String
                    var errortest: AnyObject? = errorSignUp.userInfo?["code"]
                    errortest = toString(errortest!)
                    
                    showError(self, errortest as! String, self.erreurBar)
                    var timer = NSTimer()
                    timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
                    
                    
                } else {
                    self.performSegueWithIdentifier("secondSignUp", sender: self)
                }
            }
            
            
            
        }
    }
    
    //-------------- Récupération de préview de la partie du tableau + lancement du player -----------------//
    
    //Présentation du choix de l'importation de photo
    
    @IBAction func choixMode(sender: AnyObject) {
        
        var alert = UIAlertController(title: nil, message: "Choisissez la source de votre photo", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        
        if isCamera == true{
            alert.addAction(UIAlertAction(title: "Prendre une photo", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                var image = UIImagePickerController()
                image.delegate = self
                image.sourceType = UIImagePickerControllerSourceType.Camera
                image.allowsEditing = true;
                
                self.presentViewController(image, animated: true, completion: nil)
            }))
        }
        
        
        
        alert.addAction(UIAlertAction(title: "Choisir une photo enregistrée", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            var image = UIImagePickerController()
            image.delegate = self
            image.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            image.allowsEditing = true;
            
            self.presentViewController(image, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Annuler", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    //Photo envoyé par l'utilisateur est utilisée
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        boutonPhoto.setImage(image, forState: UIControlState.Normal)
        boutonPhoto.titleLabel?.text = "Votre Photo"
        profilPicture.image = image;
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //On affiche la bar de navigation
        self.navigationController?.navigationBarHidden = false;
        
        
        //Arrondissement du bouton ajout de photo
        boutonPhoto.layer.cornerRadius = 0.5 * boutonPhoto.bounds.size.width
        
        
        //Gestion du clavier
        
        self.password.delegate = self;
        self.email.delegate = self;
        self.username.delegate = self;
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //Réglage du clavier
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true);
    }
    
    func textFieldShouldReturn(textField : UITextField ) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    
    
    
}
