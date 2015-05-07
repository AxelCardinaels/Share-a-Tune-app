//
//  SignUpFirstViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 7/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit

class SignUpFirstViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var isCamera = UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice(rawValue: 0)!)
    
    
    @IBOutlet var boutonPhoto: UIButton!
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        println("image")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = false;
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Prendre une photo", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        
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
