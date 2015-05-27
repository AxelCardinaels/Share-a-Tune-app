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
    var mediaPlayer: MPMoviePlayerController = MPMoviePlayerController()
    
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
        
        if sender.title == "Mettre l'extrait en pause" {
            mediaPlayer.pause()
            sender.setTitle("Jour l'extrait", forState: UIControlState.Normal)
            var playImage = UIImage(named: "playIcon")
            sender.setImage(playImage, forState: UIControlState.Normal)
        }else{
            var songLink = post[rowIndex].valueForKey("previewLink") as! String
            let url = NSURL(string: songLink)
            
            
            mediaPlayer.contentURL = url
            mediaPlayer.play()
            
            sender.setTitle("Mettre l'extrait en pause", forState: UIControlState.Normal)
            var pauseImage = UIImage(named: "pauseIcon")
            sender.setImage(pauseImage, forState: UIControlState.Normal)
        }
        
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
        feedTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        
        //On affiche la bar de navigation
        self.navigationController?.navigationBarHidden = false;

        
        getFollowedList()
        
        
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
        
        var lastActive: AnyObject? = currentPost.valueForKey("createdAt")
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'-'HH':'mm':'ss"
        var postDate = dateFormatter.stringFromDate(lastActive as! NSDate)
        
        var todaysDate:NSDate = NSDate()
        var actualDate:String = dateFormatter.stringFromDate(todaysDate)
        
        let startDate:NSDate = dateFormatter.dateFromString(postDate)!
        let endDate:NSDate = dateFormatter.dateFromString(actualDate)!
        
        let cal = NSCalendar.currentCalendar()
        
        var unit:NSCalendarUnit = NSCalendarUnit.CalendarUnitDay
        
        var components = cal.components(unit, fromDate: startDate, toDate: endDate, options: nil)
        
        if components.day == 0 {
            unit = NSCalendarUnit.CalendarUnitHour
            components = cal.components(unit, fromDate: startDate, toDate: endDate, options: nil)
            
            if components.hour == 0{
               
                unit = NSCalendarUnit.CalendarUnitMinute
                components = cal.components(unit, fromDate: startDate, toDate: endDate, options: nil)
                
                if components.minute == 0{
                    cell.postTime.text = "< 1Min"
                    
                }else{
                   cell.postTime.text = "\(components.minute)Min"
                }
                
            }else{
                cell.postTime.text = "\(components.hour)h"
            }
            
        }else{
            
            cell.postTime.text = "\(components.day)j"
        }
        
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
