//
//  ProfilEditViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 26/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration

class ProfilEditViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    var user = PFUser.currentUser()
    var profilPictureStock = UIImageView(image: UIImage(named: "noopf.png"))
    
    
    @IBOutlet var profilPicture: UIButton!
    
    @IBAction func updatePicture(sender: AnyObject){
        
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
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        profilPicture.setImage(image, forState: UIControlState.Normal)
        profilPictureStock.image = image
    }
    
    @IBOutlet var theScrollView: UIScrollView!
    @IBOutlet var characterCount: UILabel!
    @IBOutlet var erreurBar: UILabel!
    @IBOutlet var profilDescription: UITextView!
    @IBOutlet var profilPrenom: UITextField!
    @IBOutlet var profilNom: UITextField!
    @IBOutlet var profilEmail: UITextField!
    var actualCount = Int()
    var kbHeight = CGFloat()
    
    func doProfil(){
        
        profilPrenom.text = user?.valueForKey("prenom") as? String
        profilNom.text = user?.valueForKey("nom") as? String
        profilEmail.text = user?.valueForKey("email") as? String
        profilDescription.text = user?.valueForKey("bio") as? String
        
        var pictureFile: AnyObject? = user!.valueForKey("profilePicture")!
        pictureFile!.getDataInBackgroundWithBlock({ (imageData, error) -> Void in
            var theImage = UIImage(data: imageData!)
            self.profilPicture.setImage(theImage, forState: UIControlState.Normal)
            self.profilPictureStock.image = theImage
        })
    }
    
    func updateProfil(){
        var error="";
        var searchTerm = ""
        var termCount = NSInteger()
        
        if profilPrenom.text == "" || profilNom.text == "" || profilEmail.text == ""{
            error = "empty"
        }else{
            
            
            searchTerm = profilPrenom!.text
            termCount = count(searchTerm)
            
            let regex = NSRegularExpression(pattern: ".*[^A-Za-z\\s\\-].*", options: nil, error: nil)!
            if regex.firstMatchInString(searchTerm, options: nil, range: NSMakeRange(0, termCount)) != nil {
                error = "noSpec"
                
            }else{
                searchTerm = profilNom!.text
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
            
            if actualCount >= 0{
                
                
                if user != nil {
                    
                    var imageData = UIImagePNGRepresentation(self.profilPictureStock.image)
                    var imageFile = PFFile(name:"ProfilPicture", data: imageData)
                    
                    var emailText = profilEmail.text!
                    var emailLower = emailText.lowercaseString
                    
                    user?.email = emailLower
                    user?["prenom"] = profilPrenom.text
                    user?["nom"] = profilNom.text
                    user?["bio"] = profilDescription.text
                    user?["profilePicture"] = imageFile
                    
                    
                    user?.saveInBackgroundWithBlock({ (saved, saveError) -> Void in
                        if let saveError = saveError {
                            let errorString = saveError.userInfo?["error"] as? NSString
                            // Show the errorString somewhere and let the user try again.
                            
                            error = errorString as! String
                            var errortest: AnyObject? = saveError.userInfo?["code"]
                            errortest = toString(errortest!)
                            
                            showError(self, errortest as! String, self.erreurBar)
                            var timer = NSTimer()
                            timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
                            
                            
                        } else {
                            self.performSegueWithIdentifier("profilEdited", sender: self)
                        }
                    })
                    
                } else {
                    error = "error"
                }
                
            }else{
                error = "descriptionTooLong"
                showError(self, error, self.erreurBar)
                var timer = NSTimer()
                timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
            }
            
            
        }
        
    }
    
    func makeSaveButton(){
        var saveButton : UIBarButtonItem = UIBarButtonItem(title: "Enregister", style: UIBarButtonItemStyle.Plain, target: self, action: "updateProfil")
        self.navigationItem.rightBarButtonItem = saveButton
    }
    
    func quitKeyboard(sender: AnyObject){
        theScrollView.endEditing(true)
    }

    func registerForKeyboardNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self,selector: "keyboardWillBeShown:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // Called when the UIKeyboardDidShowNotification is sent.
    func keyboardWillBeShown(sender: NSNotification) {
        let info: NSDictionary = sender.userInfo!
        let value: NSValue = info.valueForKey(UIKeyboardFrameBeginUserInfoKey) as! NSValue
        let keyboardSize: CGSize = value.CGRectValue().size
        let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0)
        theScrollView.contentInset = contentInsets
        theScrollView.scrollIndicatorInsets = contentInsets

    }
    
    // Called when the UIKeyboardWillHideNotification is sent
    func keyboardWillBeHidden(sender: NSNotification) {
        let contentInsets: UIEdgeInsets = UIEdgeInsetsZero
        theScrollView.contentInset = contentInsets
        theScrollView.scrollIndicatorInsets = contentInsets
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profilPicture.layer.cornerRadius = 0.5 * profilPicture.bounds.size.width
        
        profilDescription.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).CGColor
        profilDescription.layer.borderWidth = 1.0
        profilDescription.layer.cornerRadius = 5
        
        makeSaveButton()
        doProfil()
        registerForKeyboardNotifications()
        
        self.profilEmail.delegate = self
        self.profilNom.delegate = self
        self.profilPrenom.delegate = self
        self.profilDescription.delegate = self
        
        var tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "quitKeyboard:")
        theScrollView.addGestureRecognizer(tap)
        
    }
    
 
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
    }
    
    
    
    func textFieldShouldReturn(textField : UITextField ) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    
    func textViewDidChange(textView: UITextView) { //Handle the text changes here
        var actualText : Int = count(textView.text) as Int
        actualCount = 120 - actualText
        characterCount.text = "\(actualCount)"
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