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

    

    
    
    var settingsContainer = ["Se déconnecter","Visiter le site de Share a Tune"]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.setHidesBackButton(true, animated: true)
        
        initialisePlayer(playerView, playerSong, playerArtist, settingsTable)
        
        let playerHasDonePlaying = NSNotificationCenter.defaultCenter().addObserver(self , selector: "hidePlayer:" , name: MPMoviePlayerPlaybackDidFinishNotification , object: nil)
        
        
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
            
        }else{
            UIApplication.sharedApplication().openURL(NSURL(string: "http://www.axelcardinaels.be/shareatuneapp")!)
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "ShowUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = PFUser.currentUser()?.username
        }
    }

}
