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

    
//-------------- Tableau contenant les settings à afficher -----------------//
    
    var settingsContainer = ["Se déconnecter","Visiter le site de Share a Tune","Editer mon profil"]

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
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "ShowUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = PFUser.currentUser()?.username
        }
    }

}
