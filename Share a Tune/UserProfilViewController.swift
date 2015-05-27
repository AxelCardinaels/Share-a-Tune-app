//
//  UserProfilViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 15/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration

class UserProfilViewController: UIViewController {
    
    
    @IBOutlet var profilPicture: UIImageView!
    var actualUserID = ""
    
    func doProfile(){
        
        var actualUser = self.title
        var profilPictureFile = PFFile()
        
        var query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: actualUser!)
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // Do something with the found objects
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        self.actualUserID = object.objectId!
                        profilPictureFile = object.valueForKey("profilePicture") as! PFFile
                        self.checkIfFollow()
                        
                        profilPictureFile.getDataInBackgroundWithBlock({ (imageData, error) -> Void in
                            var theImage = UIImage(data: imageData!)
                            self.profilPicture.image = theImage
                        })
                        
                    }
                }
            } else {
                // Log details of the failure
                println("error")
            }
        }
        
    }
    
    
    func checkIfFollow(){
        
        makeLoadingButton()
        

        
        var currentUser = PFUser.currentUser()?.objectId!
        var query = PFQuery(className:"Followers")
        query.whereKey("follower", equalTo: currentUser!)
        query.whereKey("following", equalTo: actualUserID)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                
                if objects!.count == 0{
                    self.makeFollowButton()
                }else{
                    self.makeUnfollowButton()
                }
                
            } else {
                println("Fail")
            }
        }
    }
    
    
    func followUser(){
        var following = PFObject(className: "Followers")
        following["follower"] = PFUser.currentUser()?.objectId
        following["following"] = actualUserID
        following.saveInBackground()
        
        makeUnfollowButton()
        
    }
    
    func unfollowUser(){
        
        var currentUser = PFUser.currentUser()?.username
        var query = PFQuery(className:"Followers")
        query.whereKey("follower", equalTo: currentUser!)
        query.whereKey("following", equalTo: actualUserID)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if let objects = objects as? [PFObject] {
                for object in objects {
                    object.deleteInBackground()
                    
                    self.makeFollowButton()
                }
            }
        }
        
    }
    
    func makeLoadingButton(){
        var loadingButton : UIBarButtonItem = UIBarButtonItem(title: "Chargement", style: UIBarButtonItemStyle.Plain, target: self, action: "fakeFollow")
        self.navigationItem.rightBarButtonItem = loadingButton
    }
    
    func makeFollowButton(){
        var followButton : UIBarButtonItem = UIBarButtonItem(title: "Suivre", style: UIBarButtonItemStyle.Plain, target: self, action: "followUser")
        self.navigationItem.rightBarButtonItem = followButton
    }
    
    func makeUnfollowButton(){
        var unfollowButton : UIBarButtonItem = UIBarButtonItem(title: "Suivi", style: UIBarButtonItemStyle.Plain, target: self, action: "unfollowUser")
        self.navigationItem.rightBarButtonItem = unfollowButton
        self.navigationItem.rightBarButtonItem!.tintColor = UIColor.greenColor();
    }
    
    func fakeFollow(){
        println("Gotcha")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    
    
}
