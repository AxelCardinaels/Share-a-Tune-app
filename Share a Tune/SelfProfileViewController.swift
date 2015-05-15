//
//  SelfProfileViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 13/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration

class SelfProfileViewController: UIViewController {
    
   @IBOutlet var profilPicture: UIImageView!
    
    @IBOutlet var ProfilDescription: UILabel!
    
    @IBOutlet var followersButton: UIButton!
    
    @IBOutlet var followingButton: UIButton!
    

    func doProfile(){
        
        var theUser = PFUser.currentUser()
        
        self.title = theUser?.username!
        var profilPictureFile: AnyObject? = theUser?.objectForKey("profilePicture")
        
        profilPictureFile!.getDataInBackgroundWithBlock { (imageData , imageError ) -> Void in
            
            if imageError == nil{
                let image = UIImage(data: imageData!)
                self.profilPicture.image = image
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //On cache le bouton Back
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        //Arrondissement du bouton ajout de photo + border
        profilPicture.layer.cornerRadius = 0.5 * profilPicture.bounds.size.width
        self.profilPicture.layer.borderWidth = 3.0;
        self.profilPicture.layer.borderColor = UIColor.whiteColor().CGColor

        
        
        doProfile()
        
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
