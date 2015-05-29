//
//  FeedViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 11/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration
import MediaPlayer

class FeedViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet var feedTable: UITableView!
    
    var followed = [String]()
    var post = [PFObject]()
    var followedInfo = [String : PFObject]()
    
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
        stopPlayer(playerView, feedTable)
    }
    
    
    func hidePlayer(note : NSNotification){
        stopPlayer(playerView, feedTable)
    }
    
    func getFollowedList(){
        
        
        var currentUser = PFUser.currentUser()!.objectId!
        var query = PFQuery(className: "Followers")
        query.whereKey("follower", equalTo: currentUser)
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                
                self.followed.removeAll(keepCapacity: true)
                self.followed.append(currentUser)
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        var followedUser: AnyObject? = object.valueForKey("following")
                        self.getFollowedInfos(object.valueForKey("following") as! String)
                        self.followed.append(followedUser! as! String)
                    }
                }
                self.getFollowedInfos(currentUser)
                self.getOrderedPosts()
                
            } else {
                // Log details of the failure
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
    }
    
    func getOrderedPosts(){
        
        var query = PFQuery(className:"Post")
        query.whereKey("userID", containedIn: followed)
        query.orderByDescending("createdAt")
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // The find succeeded.
                println("Successfully retrieved Posts")
                // Do something with the found objects
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        self.post.append(object)
                    }
                }
                
                self.feedTable.reloadData()
            } else {
                // Log details of the failure
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
    }
    
    func getFollowedInfos(userID : String){
        
        if userID == PFUser.currentUser()?.objectId {
            followedInfo.updateValue(PFUser.currentUser()!, forKey: userID)
        }
        
        var idUser = userID
        var query = PFUser.query()
        query!.whereKey("objectId", equalTo:userID)
        query!.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded.
                println("Successfully retrieved \(objects!.count) scores.")
                // Do something with the found objects
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        
                        self.followedInfo.updateValue(object, forKey: idUser)
                    }
                }
                
            } else {
                // Log details of the failure
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
        
    }
    
    func getPreview(sender : AnyObject){
        
        var positionButton = sender.convertPoint(CGPointZero, toView: self.feedTable)
        var indexPath = self.feedTable.indexPathForRowAtPoint(positionButton)
        var rowIndex = indexPath!.row
        var songLink = post[rowIndex].valueForKey("previewLink") as! String
        let url = NSURL(string: songLink)
        mediaPlayer.contentURL = url
        mediaPlayer.play()
        
        playerSong.text = post[rowIndex].valueForKey("songName") as? String
        playerArtist.text = post[rowIndex].valueForKey("artistName") as? String
        playerCurrentSong = (post[rowIndex].valueForKey("songName") as? String)!
        playerCurrentArtist = (post[rowIndex].valueForKey("artistName") as? String)!
        showPlayer(playerView, feedTable)
        
    }
    
    func getToStore(sender : AnyObject){
        var positionButton = sender.convertPoint(CGPointZero, toView: self.feedTable)
        var indexPath = self.feedTable.indexPathForRowAtPoint(positionButton)
        var rowIndex = indexPath!.row
        
        var itunesLink = post[rowIndex].valueForKey("itunesLink") as! String
        let url = NSURL(string: itunesLink)
        
        UIApplication.sharedApplication().openURL(url!)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //On affiche la bar de navigation
        self.navigationController?.navigationBarHidden = false;
        
        initialisePlayer(playerView, playerSong, playerArtist, feedTable)
        getFollowedList()
        
        let playerHasDonePlaying = NSNotificationCenter.defaultCenter().addObserver(self , selector: "hidePlayer:" , name: MPMoviePlayerPlaybackDidFinishNotification , object: nil)
        
        
        // Do any additional setup after loading the view.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1;
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return post.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("postCell", forIndexPath: indexPath) as! PostTableViewCell
        
        
        var currentCell = indexPath
        var currentPost = post[indexPath.row]
        var currentUser = followedInfo[currentPost.valueForKey("userID") as! String]
        
        cell.postPlay.tag = currentCell.row
        
        var lastActive: AnyObject? = currentPost.valueForKey("createdAt")
        cell.postTime.text = makeDate(lastActive!)
        cell.username.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        
        cell.userProfil.layer.cornerRadius = 0.5 * cell.userProfil.bounds.size.width
        
        cell.postArtist.text = currentPost.valueForKey("artistName") as? String
        cell.postDescription.text = currentPost.valueForKey("postDescription") as? String
        cell.postTitle.text = currentPost.valueForKey("songName") as? String
        cell.postDescription.sizeToFit()
        cell.username.setTitle(currentUser?.valueForKey("username") as? String, forState: UIControlState.Normal)
        
        if currentPost.valueForKey("itunesLink") as? String == "noLink" {
            cell.postItunes.hidden = true;
        }else{
            cell.postItunes.hidden = false;
            cell.postItunes.addTarget(self, action: "getToStore:", forControlEvents: .TouchUpInside)
        }
        
        
        if currentPost.valueForKey("previewLink") as? String == "noPreview" {
            cell.postPlay.hidden = true
        }else{
            cell.postPlay.hidden = false;
            cell.postPlay.addTarget(self, action: "getPreview:", forControlEvents: .TouchUpInside)
        }
        
        if currentPost.valueForKey("location") as? String == "noLocalisation" {
            cell.postLocation.text = "Inconnu"
        }else{
            cell.postLocation.text = currentPost.valueForKey("location") as? String
        }
        
        
        if currentUser?.valueForKey("profilePicture")! != nil{
            var pictureFile: AnyObject? = currentUser?.valueForKey("profilePicture")!
            pictureFile!.getDataInBackgroundWithBlock({ (imageData, error) -> Void in
                var theImage = UIImage(data: imageData!)
                cell.userProfil.image = theImage
            })
        }
        
        if currentPost.valueForKey("coverLink") as? String == "customImage" {
            var profilPictureFile: AnyObject? = currentPost.valueForKey("postImage")
            
            profilPictureFile!.getDataInBackgroundWithBlock { (imageData , imageError ) -> Void in
                
                if imageError == nil{
                    let image = UIImage(data: imageData!)
                    cell.postPicture.image = image
                }
            }
        }else{
            if currentPost.valueForKey("coverLink") as? String == "noCover"{
                
                var cover = UIImage(named: "noCover")
                cell.postPicture.image = cover
                
            }else{
                var finalURL = NSURL(string: currentPost.valueForKey("coverLink") as! String)
                let request: NSURLRequest = NSURLRequest(URL: finalURL!)
                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                    if error == nil {
                        var image = UIImage(data: data)
                        
                        
                        cell.postPicture.image = image
                        
                    }
                    else {
                        println("Error: \(error.localizedDescription)")
                    }
                })
            }
        }
        
        return cell;
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showUserProfilFeed" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            var positionButton = sender!.convertPoint(CGPointZero, toView: self.feedTable)
            var indexPath = self.feedTable.indexPathForRowAtPoint(positionButton)
            var theCell = feedTable.cellForRowAtIndexPath(indexPath!)
            
            var theName: AnyObject = sender?.currentTitle! as! AnyObject
            
            println(theName)
            secondView.title = theName as! String
            println("done")
        }
        
        if segue.identifier == "ShowUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = PFUser.currentUser()?.username
            println("done")
        }
    }
    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.setHidesBackButton(true, animated: true)
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
