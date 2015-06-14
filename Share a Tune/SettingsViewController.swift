//
//  SettingsViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 26/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration
import MediaPlayer

class SettingsViewController: UIViewController, UITableViewDelegate {

    
    @IBOutlet var notificationIcon: UIBarButtonItem!
    
    
//-------------- Déclarations + Gestions du player Musical -----------------//
    
    @IBOutlet var settingsTable: UITableView!
    @IBOutlet var playerView: UIView!
    @IBOutlet var playerSong: UILabel!
    @IBOutlet var playerArtist: UILabel!
    
    @IBAction func playerPause(sender: AnyObject) {
        
        if playerIsPaused == true{
            playPlayer(sender as! UIButton, playerSong, playerArtist)
        }else{
            pausePlayer(sender as! UIButton)
        }
    }
    
    @IBAction func playerStop(sender: AnyObject) {
        stopPlayer(playerView, settingsTable)
    }
    
    func hidePlayer(note : NSNotification){
        stopPlayer(playerView, settingsTable)
    }

    
//-------------- Supression de l'utilisateur -----------------//
    
    func cleanUser(userId : String){
        var query = PFQuery(className: "Post")
        query.whereKey("userID", equalTo: userId)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if let objects = objects as? [PFObject] {
                for object in objects {
                    object.deleteInBackground()
                }
            }
        }
        
        query = PFQuery(className: "Comments")
        query.whereKey("PosterId", equalTo: userId)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if let objects = objects as? [PFObject] {
                for object in objects {
                    object.deleteInBackground()
                }
            }
        }
        
        query = PFQuery(className: "Followers")
        query.whereKey("follower", equalTo: userId)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if let objects = objects as? [PFObject] {
                for object in objects {
                    object.deleteInBackground()
                }
            }
        }
        
        query = PFQuery(className: "Likes")
        query.whereKey("likerId", equalTo: userId)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if let objects = objects as? [PFObject] {
                for object in objects {
                    object.deleteInBackground()
                }
            }
        }
        
        query = PFQuery(className: "Notifications")
        query.whereKey("likerId", equalTo: userId)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if let objects = objects as? [PFObject] {
                for object in objects {
                    object.deleteInBackgroundWithBlock({ (succes, error) -> Void in
                        if succes{
                            
                        }
                    })
                }
            }
        }
        
        query = PFUser.query()!
        query.whereKey("objectId", equalTo: userId)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if let objects = objects as? [PFObject] {
                for object in objects {
                    object.deleteInBackgroundWithBlock {
                        (success: Bool, error: NSError?) -> Void in
                        if (success){
                            
                            PFUser.logOut()
                            var currentUser = PFUser.currentUser()
                            self.performSegueWithIdentifier("logout", sender: self)
                        } else {
                            println("fail")
                        }
                    }
                }
            }
        }


    }
    
//-------------- Tableau contenant les settings à afficher -----------------//
    
    
    var settingsContainer = ["Se déconnecter","Visiter le site de Share a Tune","Editer mon profil","Supprimer mon profil"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //Initialisation du player
        
        initialisePlayer(playerView, playerSong, playerArtist, settingsTable)
        let playerHasDonePlaying: Void = NSNotificationCenter.defaultCenter().addObserver(self , selector: "hidePlayer:" , name: MPMoviePlayerPlaybackDidFinishNotification , object: nil)
        
        makeNotifLabel(self, notificationIcon)
        getNotif()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1;
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return settingsContainer.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("classicCell", forIndexPath: indexPath) as! UITableViewCell;
        
        cell.textLabel!.text = settingsContainer[indexPath.row]
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        let indexPath = tableView.indexPathForSelectedRow();
        let currentCell = tableView.cellForRowAtIndexPath(indexPath!)
        var cellTitle = currentCell?.textLabel!.text
        
        if cellTitle! == "Se déconnecter" {
            stopPlayer(playerView, settingsTable)
            PFUser.logOut()
            var currentUser = PFUser.currentUser()
            performSegueWithIdentifier("logout", sender: self)
            
        }
        
        if cellTitle! == "Visiter le site de Share a Tune"{
            UIApplication.sharedApplication().openURL(NSURL(string: "http://www.axelcardinaels.be/shareatuneapp")!)
        }
        
        if cellTitle! == "Editer mon profil"{
            performSegueWithIdentifier("editProfil", sender: self)
        }
        
        if cellTitle! == "Supprimer mon profil" {
            var alert = UIAlertController(title: nil, message: "Êtres vous sur de vouloir supprimer votre profil ? Cette action est irrévoquable et vous allez beaucoup manquer à vos amis !", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            
            alert.addAction(UIAlertAction(title: "Supprimer mon profil", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            
                var userId = PFUser.currentUser()?.objectId
                
                self.cleanUser(userId!)
                
                self.dismissViewControllerAnimated(true, completion: nil)
                
                
            }))
            
            alert.addAction(UIAlertAction(title: "Annuler", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                alert.dismissViewControllerAnimated(true, completion: nil)
            }))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "ShowUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = PFUser.currentUser()?.username
        }
    }

}
