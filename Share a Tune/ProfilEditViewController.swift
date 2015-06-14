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
    
    
    @IBOutlet var notificationIcon: UIBarButtonItem!
    
    
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    var user = PFUser.currentUser()
    var profilPictureStock = UIImageView(image: UIImage(named: "noopf.png"))
    var imageHasChanged = false
    
    //-------------- gestion de l'importation de photo -----------------//
    
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
        profilPicture.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
        profilPictureStock.image = image
        imageHasChanged = true
    }
    
    
    //-------------- Variables générales pour la vue -----------------//
    
    @IBOutlet var theScrollView: UIScrollView!
    @IBOutlet var characterCount: UILabel!
    @IBOutlet var erreurBar: UILabel!
    @IBOutlet var profilDescription: UITextView!
    @IBOutlet var profilPrenom: UITextField!
    @IBOutlet var profilNom: UITextField!
    @IBOutlet var profilEmail: UITextField!
    var actualCount = Int()
    var kbHeight = CGFloat()
    
    
    //-------------- Création du profil -----------------//
    
    
    func doProfil(){
        
        profilPrenom.text = user?.valueForKey("prenom") as? String
        profilNom.text = user?.valueForKey("nom") as? String
        profilEmail.text = user?.valueForKey("email") as? String
        
        if user?.valueForKey("bio") as? String == "noBio" {
            profilDescription.text = ""
        }else{
            profilDescription.text = user?.valueForKey("bio") as? String
        }
        
        
        var pictureFile: AnyObject? = user!.valueForKey("profilePicture")!
        
        if isConnectedToNetwork() == true{
            pictureFile!.getDataInBackgroundWithBlock({ (imageData, error) -> Void in
                var theImage = UIImage(data: imageData!)
                self.profilPicture.setImage(theImage, forState: UIControlState.Normal)
                self.profilPicture.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
                self.profilPictureStock.image = theImage
                
                var username : String = self.user?.valueForKey("username") as! String
                
            })
        }else{
            var error = "noInternet"
            showError(self,error,erreurBar )
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(4.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
        }
        
    }
    
    //-------------- Check + enregistrement du profil sur le serveur -----------------//
    
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
            var senderButton = self.navigationItem.rightBarButtonItem
            if actualCount >= 0{
                
                
                if user != nil {
                    
                    
                    var spinner = activityIndicatorHeaderMake()
                    var ButtonSpinner : UIBarButtonItem = UIBarButtonItem(customView: spinner)
                    self.navigationItem.rightBarButtonItem = nil
                    self.navigationItem.rightBarButtonItem = ButtonSpinner
                    
                    
                    
                    
                    
                    var emailText = profilEmail.text!
                    var emailLower = emailText.lowercaseString
                    
                    user?.email = emailLower
                    user?["prenom"] = profilPrenom.text
                    user?["nom"] = profilNom.text
                    if actualCount == 120 {
                        user?["bio"] = "noBio"
                    }else{
                        user?["bio"] = profilDescription.text
                    }
                    
                    
                    if imageHasChanged == true{
                        var imageData = UIImageJPEGRepresentation(self.profilPictureStock.image, 0.5)
                        var imageFile = PFFile(name:"ProfilPicture", data: imageData)
                        user?["profilePicture"] = imageFile
                    }
                    
                    
                    
                    
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
                            
                            activityIndicatorButton.stopAnimating()
                            UIApplication.sharedApplication().endIgnoringInteractionEvents()
                            self.navigationItem.rightBarButtonItem = nil
                            self.makeSaveButton()
                            self.performSegueWithIdentifier("ProfilEdited", sender: self)
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
    
    
    //-------------- Gestion du clavier -----------------//
    
    //Cache le clavier à la fin de l'édition
    
    func quitKeyboard(sender: AnyObject){
        theScrollView.endEditing(true)
    }
    
    //Ajout d'événement pour le clavier ( Apparait , disparait)
    
    func registerForKeyboardNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self,selector: "keyboardWillBeShown:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // La vue remonte quand le clavier apparait
    func keyboardWillBeShown(sender: NSNotification) {
        let info: NSDictionary = sender.userInfo!
        let value: NSValue = info.valueForKey(UIKeyboardFrameBeginUserInfoKey) as! NSValue
        let keyboardSize: CGSize = value.CGRectValue().size
        let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0)
        theScrollView.contentInset = contentInsets
        theScrollView.scrollIndicatorInsets = contentInsets
        
    }
    
    // la vue se remet en place quand le clavier disparait
    func keyboardWillBeHidden(sender: NSNotification) {
        let contentInsets: UIEdgeInsets = UIEdgeInsetsZero
        theScrollView.contentInset = contentInsets
        theScrollView.scrollIndicatorInsets = contentInsets
    }
    
    
    //Gestion du compteur de caractères
    
    func textViewDidChange(textView: UITextView) { //Handle the text changes here
        var actualText : Int = count(textView.text) as Int
        actualCount = 120 - actualText
        characterCount.text = "\(actualCount)"
    }
    
    //Gestion de la disparition du clavier en cliquant sur le bouton "retour"
    func textFieldShouldReturn(textField : UITextField ) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        killPlayer()
        
        profilPicture.layer.cornerRadius = 0.5 * profilPicture.bounds.size.width
        
        profilDescription.layer.borderColor = UIColor(red: 203/255, green: 20/255, blue: 102/255, alpha: 0.8).CGColor
        profilDescription.layer.borderWidth = 0.85
        profilEmail.layer.borderWidth = 0.85
        profilEmail.layer.borderColor = UIColor(red: 203/255, green: 20/255, blue: 102/255, alpha: 0.8).CGColor
        profilNom.layer.borderWidth = 0.85
        profilNom.layer.borderColor = UIColor(red: 203/255, green: 20/255, blue: 102/255, alpha: 0.8).CGColor
        profilPrenom.layer.borderWidth = 0.85
        profilPrenom.layer.borderColor = UIColor(red: 203/255, green: 20/255, blue: 102/255, alpha: 0.8).CGColor
        
        
        
        
        
        
        makeSaveButton()
        doProfil()
        registerForKeyboardNotifications()
        
        self.profilEmail.delegate = self
        self.profilNom.delegate = self
        self.profilPrenom.delegate = self
        self.profilDescription.delegate = self
        
        var tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "quitKeyboard:")
        theScrollView.addGestureRecognizer(tap)
        
        makeNotifLabel(self, notificationIcon)
        getNotif()
        
    }
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "ProfilEdited" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = PFUser.currentUser()?.username
        }
        if segue.identifier == "ShowUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = PFUser.currentUser()?.username
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
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
