//
//  NotifcationsViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 7/06/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import SystemConfiguration
import Foundation
import MediaPlayer

class NotifcationsViewController: UIViewController , UITableViewDelegate{
    
    
    
    //-------------- Récupération des notifications -----------------//
    
    @IBOutlet var notificationIcon: UIBarButtonItem!
    @IBOutlet var erreurBar: UILabel!
    @IBOutlet var noInternetLabel: UILabel!
    @IBOutlet var noNotifLabel: UILabel!
    
    var error=""
    
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    
    
    //-------------- Déclarations + Gestions du player Musical -----------------//
    
    
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
        stopPlayer(playerView, notificationTable)
    }
    
    
    func hidePlayer(note : NSNotification){
        stopPlayer(playerView, notificationTable)
    }
    
    
    
    var refresher : UIRefreshControl = UIRefreshControl()
    
    func refreshData(){
        
        getNotifcations()
        self.refresher.endRefreshing()
    }
    
    
    var notificationsList = [PFObject]()
    var senderId = [String]()
    var senderList = [String : PFObject]()
    var postsId = [String]()
    var posts = [String : PFObject]()
    var thingToGo = ""
    var cellToSend = UITableViewCell()
    var profilContainer = UIImageView()
    var currentUser = PFUser.currentUser()
    
    
    
    
    func getUserPicture(){
        
        if currentUser!.valueForKey("profilePicture") != nil{
            var pictureFile: AnyObject? = currentUser!.valueForKey("profilePicture")!
            pictureFile!.getDataInBackgroundWithBlock({ (imageData, error) -> Void in
                var theImage = UIImage(data: imageData!)
                self.profilContainer = UIImageView(image: theImage, highlightedImage: nil)
            })
        }
    }
    
    func getNotifcations(){
        notifLabel.alpha = 0
        noInternetLabel.alpha = 0
        notificationTable.alpha = 1
        if isConnectedToNetwork(){
            getUserPicture()
            var myself = PFUser.currentUser()?.objectId
            var query = PFQuery(className: "Notifications")
            query.whereKey("authorId", equalTo: myself!)
            query.orderByDescending("createdAt")
            query.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]?, error: NSError?) -> Void in
                
                if error == nil {
                    // The find succeeded.
                    notifNumber = 0
                    self.notificationsList.removeAll(keepCapacity: true)
                    self.senderId.removeAll(keepCapacity: true)
                    self.postsId.removeAll(keepCapacity: true)
                    
                    if let objects = objects as? [PFObject] {
                        
                        if objects.count == 0 {
                            self.noNotifLabel.alpha = 1
                            self.notificationTable.alpha = 0.5
                            
                        }else{
                            for object in objects {
                                self.notificationsList.append(object)
                                self.senderId.append((object.valueForKey("likerId") as? String)!)
                                self.postsId.append((object.valueForKey("postId") as? String)!)
                                if object.valueForKey("sawNotif")! as! NSObject == false {
                                    
                                    var query = PFQuery(className:"Notifications")
                                    query.getObjectInBackgroundWithId(object.valueForKey("objectId") as! String) {
                                        (notification : PFObject?, error: NSError?) -> Void in
                                        if error != nil {
                                            println(error)
                                        } else if let notificationUpdate = notification {
                                            notificationUpdate["sawNotif"] = true
                                            notificationUpdate.saveInBackground()
                                        }
                                    }
                                }
                                
                            }
                            
                            self.getUsers()
                            self.getPosts()
                            self.notificationTable.reloadData()
                        }
                        
                    }
                    
                    
                } else {
                    // Log details of the failure
                    println("Error: \(error!) \(error!.userInfo!)")
                }
            }
        }else{
            error = "noInternet"
            showError(self,error,erreurBar)
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(4.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
            noInternetLabel.alpha = 1
            notificationTable.alpha = 0.5
        }
        
        
    }
    
    
    func getUsers(){
        var query = PFUser.query()
        query!.whereKey("objectId", containedIn: senderId)
        query!.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                self.senderList.removeAll(keepCapacity: true)
                if let objects = objects as? [PFObject] {
                    
                    for object in objects {
                        self.senderList.updateValue(object, forKey: (object.valueForKey("objectId") as? String)! )
                        self.notificationTable.reloadData()
                    }
                }
                
                self.notificationTable.reloadData()
                
            } else {
                println("Error: \(error!) \(error!.userInfo!)")
            }
            
        }
        
    }
    
    func getPosts(){
        var query = PFQuery(className: "Post")
        query.whereKey("objectId", containedIn: postsId)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                self.posts.removeAll(keepCapacity: true)
                if let objects = objects as? [PFObject] {
                    
                    for object in objects {
                        self.posts.updateValue(object, forKey: (object.valueForKey("objectId") as? String)! )
                    }
                }
                
                self.notificationTable.reloadData()
                
            } else {
                println("Error: \(error!) \(error!.userInfo!)")
            }
            
        }
    }
    
    
    
    
    //-------------- Déclaration des variables utilisées pour le tableau des notifcations -----------------//
    
    
    @IBOutlet var notificationTable: UITableView!
    var height = CGFloat()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getNotifcations()
        
        //Mise en place du Refresher
        
        refresher.addTarget(self, action: "refreshData", forControlEvents: UIControlEvents.ValueChanged)
        notificationTable.addSubview(refresher)
        
        //Initialisation du player
        
        initialisePlayer(playerView, playerSong, playerArtist, notificationTable)
        
        let playerHasDonePlaying: Void = NSNotificationCenter.defaultCenter().addObserver(self , selector: "hidePlayer:" , name: MPMoviePlayerPlaybackDidFinishNotification , object: nil)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //-------------- On cache le bouton back -----------------//
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        notificationTable.reloadData()
    }
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        //Si on clique sur l'icone du profil, le titre du profil est l'username de l'utilisateur actual
        
        if segue.identifier == "ShowUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = PFUser.currentUser()?.username
        }
        
        if segue.identifier == "showNotifUser" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = thingToGo
        }
        
        if segue.identifier == "showDetailPublication"{
            
            var secondView: SingleProjectViewController = segue.destinationViewController as! SingleProjectViewController
            var imageContainer = cellToSend.valueForKey("postPicture") as? UIImageView
            
            secondView.idToFind = thingToGo
            
            if imageContainer != nil {
                secondView.imageToShow = imageContainer!
                secondView.imageProfilToShow = profilContainer
            }
            
            
        }
        
        if segue.identifier == "showComments"{
            var secondView: CommentairesViewController = segue.destinationViewController as! CommentairesViewController
            secondView.idToFind = thingToGo
        }
        
        
        
        
    }
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1;
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return notificationsList.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("notificationCell", forIndexPath: indexPath) as! NotificationTableViewCell
        
        var currentNotif = notificationsList[indexPath.row] as PFObject
        var currentSender = senderList[currentNotif.valueForKey("likerId") as! String]
        var currentPost = posts[currentNotif.valueForKey("postId") as! String]
        var notifType = currentNotif.valueForKey("notificationType") as? String
        var notifDate: AnyObject? = currentNotif.valueForKey("createdAt")
        var postType = currentPost?.valueForKey("coverLink") as? String
        var labelString = NSMutableAttributedString()
        
        
        var senderName = ""
        var senderNameLenght = Int()
        if currentSender != nil{
            senderName = currentSender?.valueForKey("username") as! String
            senderNameLenght = count(senderName)
        }
        
        var notifFinalDate : String = ""
        
        if notifDate != nil {
            notifFinalDate = makeDate(notifDate!)
        }
        
        
        if notifType == "follow" {
            
            var theString = "\(senderName) vous suit désormais. - \(notifFinalDate)"
            
            labelString = NSMutableAttributedString(string: theString, attributes: [NSFontAttributeName:UIFont(name: "Avenir Book", size: 15.0)!])
            labelString.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir Medium", size: 15.0)!, range: NSRange(location: 0,length: senderNameLenght))
            labelString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blackColor(), range: NSRange(location: 0,length: senderNameLenght))
            
            
            cell.notificationText.attributedText = labelString
            cell.accessibilityLabel = "\(cell.notificationText.text!) . Appuyez pour afficher son profil"
            
            
            
            var profilPictureFile: AnyObject? = PFUser.currentUser()?.valueForKey("profilePicture")
            
            if profilPictureFile != nil{
                profilPictureFile!.getDataInBackgroundWithBlock { (imageData , imageError ) -> Void in
                    
                    if imageError == nil{
                        let image = UIImage(data: imageData!)
                        cell.postPicture.image = image
                    }
                }
            }
        }else{
            
            if notifType == "like"{
                
                var theString = "\(senderName) a aimé votre publication. -  \(notifFinalDate)"
                
                labelString = NSMutableAttributedString(string: theString, attributes: [NSFontAttributeName:UIFont(name: "Avenir Book", size: 15.0)!])
                
                
                labelString.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir Medium", size: 15.0)!, range: NSRange(location: 0,length: senderNameLenght))
                labelString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blackColor(), range: NSRange(location: 0,length: senderNameLenght))
                
                labelString.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir Medium", size: 15.0)!, range: NSRange(location: senderNameLenght+14,length: 11))
                labelString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blackColor(), range: NSRange(location: senderNameLenght+14,length: 11))
                
                
                cell.notificationText.attributedText = labelString
                cell.accessibilityLabel = "\(cell.notificationText.text!) . Appuyez pour afficher la publication"
            }
            
            if notifType == "comment"{
                
                var theString = "\(senderName) a commenté votre publication. - \(notifFinalDate)"
                
                labelString = NSMutableAttributedString(string: theString, attributes: [NSFontAttributeName:UIFont(name: "Avenir Book", size: 15.0)!])
                
                
                labelString.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir Medium", size: 15.0)!, range: NSRange(location: 0,length: senderNameLenght))
                labelString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blackColor(), range: NSRange(location: 0,length: senderNameLenght))
                
                labelString.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir Medium", size: 15.0)!, range: NSRange(location: senderNameLenght+17,length: 11))
                labelString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blackColor(), range: NSRange(location: senderNameLenght+18,length: 11))
                
                
                cell.notificationText.attributedText = labelString
                cell.accessibilityLabel = "\(cell.notificationText.text!) . Appuyez pour afficher les commentaires de la publication"
            }
            
            
            //On Chope la photo du post
            
            if postType != nil {
                
                if postType == "customImage" {
                    var profilPictureFile: AnyObject? = currentPost!.valueForKey("postImage")
                    
                    if profilPictureFile != nil {
                        profilPictureFile!.getDataInBackgroundWithBlock { (imageData , imageError ) -> Void in
                            
                            if imageError == nil{
                                let image = UIImage(data: imageData!)
                                cell.postPicture.image = image
                            }
                        }
                    }
                    
                    
                }else{
                    
                    if postType == "noCover"{
                        
                        var cover = UIImage(named: "noCover")
                        cell.postPicture.image = cover
                        
                    }else{
                        
                        var finalURL = NSURL(string: currentPost!.valueForKey("coverLink") as! String)
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
            }
            
            
            
            
        }
        
        var profilPictureFile: AnyObject? = currentSender?.valueForKey("profilePicture")
        
        if profilPictureFile != nil{
            profilPictureFile!.getDataInBackgroundWithBlock { (imageData , imageError ) -> Void in
                
                if imageError == nil{
                    let image = UIImage(data: imageData!)
                    cell.profilPicture.image = image
                }
            }
        }
        
        
        
        if currentNotif.valueForKey("clickNotif") as! NSObject == false{
            cell.backgroundColor = UIColor(red:0.0, green:0.0,blue:0.0,alpha:0.04)
        }else{
            cell.backgroundColor = UIColor(red:0.0, green:0.0,blue:0.0,alpha:0.0)
        }
        
        
        
        cell.notificationText.sizeToFit()
        height = cell.notificationText.frame.height + 25
        
        
        
        //On arrondi la photo
        
        cell.profilPicture.layer.cornerRadius = 0.5 * cell.profilPicture.bounds.size.width
        
        
        return cell;
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return height
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var currentNotif = notificationsList[indexPath.row] as PFObject
        var notifType = currentNotif.valueForKey("notificationType") as? String
        var theCell = notificationTable.cellForRowAtIndexPath(indexPath)
        
        var query = PFQuery(className:"Notifications")
        query.getObjectInBackgroundWithId(currentNotif.valueForKey("objectId") as! String) {
            (notification : PFObject?, error: NSError?) -> Void in
            if error != nil {
                println(error)
            } else if let notificationUpdate = notification {
                notificationUpdate["clickNotif"] = true
                notificationUpdate.saveInBackground()
            }
        }
        
        
        
        if notifType == "follow"{
            var currentSender = senderList[currentNotif.valueForKey("likerId") as! String]
            thingToGo = currentSender?.valueForKey("username") as! String
            
            self.performSegueWithIdentifier("showNotifUser", sender: self)
            
            
        }else{
            thingToGo = currentNotif.valueForKey("postId") as! String
            cellToSend = theCell!
            
            if notifType == "like"{
                self.performSegueWithIdentifier("showDetailPublication", sender: self)
            }
            
            if notifType == "comment"{
                self.performSegueWithIdentifier("showComments", sender: self)
            }
        }
        
        
        
    }
    
    
    
    
    
    
    
}
