//
//  SingleProjectViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 9/06/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration
import MediaPlayer

class SingleProjectViewController: UIViewController, UITextViewDelegate {
    
    var idToFind = String()
    var authorId = String()
    
    @IBOutlet var postImage: UIImageView!
    var imageToShow = UIImageView()
    
    @IBOutlet var postProfil: UIImageView!
    var imageProfilToShow = UIImageView()
    
    @IBOutlet var profilName: UIButton!
    @IBOutlet var postPlace: UILabel!
    @IBOutlet var songName: UILabel!
    @IBOutlet var artistName: UILabel!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var postDescription: UILabel!
    @IBOutlet var likeNumber: UIButton!
    @IBOutlet var commentNumber: UIButton!
    @IBOutlet var postDate: UILabel!
    @IBOutlet var itunesButton: UIButton!
    @IBOutlet var previewSlider: UISlider!
    @IBOutlet var infoHeight: NSLayoutConstraint!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var notificationIcon: UIBarButtonItem!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var unlikeButton: UIButton!
    @IBOutlet var contentView: UIScrollView!
    var actionToDo : String = ""
    
    
    var error = ""
    @IBOutlet var erreurBar: UILabel!
    @IBOutlet var noInternetLabel: UILabel!
    
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    var refresher : UIRefreshControl = UIRefreshControl()
    
    func refreshData(){
        
        doPost()
        self.refresher.endRefreshing()
    }
    
    
    
    var previewLink = "noPreview"
    var itunesLink = ""
    
    var postLiked = false;
    
    @IBAction func previewButton(sender: AnyObject) {
        var itunesLink = previewLink
        let url = NSURL(string: itunesLink)
        
        UIApplication.sharedApplication().openURL(url!)
    }
    
    @IBAction func playPreview(sender: AnyObject) {
        
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.previewSlider.alpha = 1
            
        })
        
        if playerIsPlaying == false{
            if playerCurrentSong != self.songName.text{
                let url = NSURL(string: previewLink)
                mediaPlayer.contentURL = url
                playerCurrentSong = songName.text!
                playerCurrentArtist = artistName.text!
            }else{
                if playerIsPaused == false {
                    let url = NSURL(string: previewLink)
                    mediaPlayer.contentURL = url
                    playerCurrentSong = songName.text!
                    playerCurrentArtist = artistName.text!
                }
            }
            
            mediaPlayer.play()
            var pauseImage = UIImage(named: "pauseIcon")
            playButton.setImage(pauseImage, forState: UIControlState.Normal)
            playButton.setTitle("Mettre l'extrait en pause", forState: UIControlState.Normal)
            playerIsPlaying = true;
            playerIsPaused = false;
            playerCurrentSong = songName.text!
            playerCurrentArtist = artistName.text!
            
        }else{
            if playerCurrentSong != self.songName.text{
                let url = NSURL(string: previewLink)
                mediaPlayer.contentURL = url
                playerCurrentSong = songName.text!
                mediaPlayer.play()
                var pauseImage = UIImage(named: "pauseIcon")
                playButton.setImage(pauseImage, forState: UIControlState.Normal)
                playButton.setTitle("Mettre l'extrait en pause", forState: UIControlState.Normal)
                playerIsPlaying = true;
                playerIsPaused = false
                playerCurrentSong = songName.text!
                playerCurrentArtist = artistName.text!
            }else{
                mediaPlayer.pause()
                var playImage = UIImage(named: "playIcon")
                playButton.setImage(playImage, forState: UIControlState.Normal)
                playButton.setTitle("Jouer l'extrait", forState: UIControlState.Normal)
                playerIsPaused = true;
                playerIsPlaying = false;
            }
            
            
        }
        
    }
    
    func getAuthor(){
        var query = PFUser.query()
        query!.whereKey("objectId", equalTo:authorId)
        query!.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        self.authorId = (object.valueForKey("objectId") as? String)!
                        var username = object.valueForKey("username") as? String
                        self.profilName.setTitle(username, forState: UIControlState.Normal)
                        self.profilName.accessibilityLabel = "Afficher le profil de \(username!)"
                        self.profilName.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
                        if self.actionToDo == "like"{
                            self.likePost()
                        }
                        
                        if self.actionToDo == "unlike"{
                            self.unlikePost()
                        }
                    }
                }
                
            } else {
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
    }
    
    func getLikes(){
        var query = PFQuery(className: "Likes")
        query.whereKey("postId", equalTo:idToFind)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [PFObject] {
                    
                    self.likeNumber.setTitle("\(objects.count) j'aime", forState: UIControlState.Normal)
                    self.likeNumber.accessibilityLabel = "Afficher les \(objects.count) mentions j'aime pour cette publication"
                    for object in objects {
                        var likerId = object.valueForKey("likerId") as? String
                        var currentId = PFUser.currentUser()?.valueForKey("objectId") as? String
                        
                        if likerId == currentId {
                            self.likeButton.alpha = 0
                            self.unlikeButton.alpha = 1
                            self.postLiked = true;
                        }
                    }
                }
                
            } else {
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
    }
    
    func getComments(){
        var query = PFQuery(className: "Comments")
        query.whereKey("postId", equalTo:idToFind)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [PFObject] {
                    
                    self.commentNumber.setTitle("\(objects.count) avis", forState: UIControlState.Normal)
                    self.commentNumber.accessibilityLabel = "Afficher les \(objects.count) commentaires pour cette publication"
                }
                
            } else {
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
    }
    
    @IBAction func likeButtonClick(sender: AnyObject) {
        
        likePost()
        likeButton.enabled = false
    }
    
    func likePost(){
        var like = PFObject(className: "Likes")
        like["postId"] = idToFind
        like["likerId"] = PFUser.currentUser()?.objectId
        like.saveInBackgroundWithBlock { (saved, error) -> Void in
            if saved != false{
                println("Like")
                
                var icon = UIImage(named: "likeActionIcon")
                var justLikedIcon = UIImageView(image: icon)
                justLikedIcon.frame = CGRect(x: self.view!.frame.origin.x, y: self.view!.frame.origin.y, width: 0,height: 0)
                justLikedIcon.center.x = self.playButton.center.x
                justLikedIcon.center.y = self.playButton.center.y + 60
                justLikedIcon.tag = 2
                
                
                UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                    justLikedIcon.frame = CGRect(x: self.view!.frame.origin.x, y: self.view!.frame.origin.y, width: 110,height: 110)
                    justLikedIcon.center.x = self.playButton.center.x
                    justLikedIcon.center.y = self.playButton.center.y + 60
                    }, completion: {
                        (finished: Bool) -> Void in
                        
                        
                        // Fade in
                        UIView.animateWithDuration(0.4, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                            justLikedIcon.alpha = 0
                            
                            var timer = NSTimer()
                            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("deleteHeart"), userInfo: nil, repeats: true)

                            
                            }, completion: nil)
                })
                
                
                self.view.addSubview(justLikedIcon)
                self.postLiked = true;
                self.unlikeButton.alpha = 1
                self.likeButton.alpha = 0
                self.getLikes()
                self.unlikeButton.enabled = true
                
            }
        }
        
        
        if PFUser.currentUser()?.objectId != authorId {
            var notification = PFObject(className: "Notifications")
            println(authorId)
            notification["postId"] = idToFind
            notification["authorId"] = authorId
            notification["likerId"] = PFUser.currentUser()?.objectId
            notification["notificationType"] = "like"
            notification["sawNotif"] = false
            notification["clickNotif"] = false
            notification.saveInBackground()
        }
        
    }
    
    
    func deleteHeart(){
        for subview in self.view.subviews {
            if (subview.tag == 2) {
                
            }
        }
    }
    
    
    @IBAction func unlikeButtonClicked(sender: AnyObject) {
        unlikePost()
        unlikeButton.enabled = false
    }
    
    func unlikePost(){
        var currentUserId = PFUser.currentUser()?.objectId
        var query = PFQuery(className:"Likes")
        query.whereKey("postId", equalTo: idToFind)
        query.whereKey("likerId", equalTo: currentUserId!)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if let objects = objects as? [PFObject] {
                for object in objects {
                    object.deleteInBackgroundWithBlock({ (deleted, error) -> Void in
                        if deleted != false{
                            self.getLikes()
                            self.postLiked = false;
                            self.unlikeButton.alpha = 0
                            self.likeButton.alpha = 1
                            self.likeButton.enabled = true
                            
                        }
                    })
                    
                }
            }
        }
        
        query = PFQuery(className:"Notifications")
        query.whereKey("postId", equalTo: idToFind)
        query.whereKey("likerId", equalTo: currentUserId!)
        query.whereKey("authorId", equalTo: authorId)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if let objects = objects as? [PFObject] {
                for object in objects {
                    object.deleteInBackground()
                    
                }
            }
        }
    }
    
    
    
    
    
    func resetPlayer(note : NSNotification){
        playerIsPlaying = false;
        playerIsPaused = false;
        playerCurrentSong = "Titre du morceau"
        playerCurrentArtist = "Artiste"
        var playImage = UIImage(named: "playIcon")
        playButton.setImage(playImage, forState: UIControlState.Normal)
        playButton.setTitle("Jouer l'extrait", forState: UIControlState.Normal)
        
    }
    
    
    func updateSlider(sender:AnyObject){
        previewSlider.value = Float(mediaPlayer.currentPlaybackTime)
    }
    
    
    @IBAction func sliderChangeValue(sender: AnyObject) {
        mediaPlayer.currentPlaybackTime = NSTimeInterval(previewSlider.value)
    }
    
    func cleanPost(postId : String){
        var query = PFQuery(className: "Comments")
        query.whereKey("postId", equalTo: postId)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if let objects = objects as? [PFObject] {
                for object in objects {
                    object.deleteInBackground()
                }
            }
        }
        query = PFQuery(className: "Likes")
        query.whereKey("postId", equalTo: postId)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if let objects = objects as? [PFObject] {
                for object in objects {
                    object.deleteInBackground()
                }
            }
        }
        
        query = PFQuery(className: "Notifications")
        query.whereKey("postId", equalTo: postId)
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
    }
    
    @IBAction func deletePostAlert(sender: AnyObject) {
        var alert = UIAlertController(title: nil, message: "Êtres vous sur de vouloir supprimer cette publication ?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        
        alert.addAction(UIAlertAction(title: "Supprimer la publication", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            var query = PFQuery(className:"Post")
            query.whereKey("objectId", equalTo: self.idToFind)
            query.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]?, error: NSError?) -> Void in
                
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        self.cleanPost(self.idToFind)
                        object.deleteInBackground()
                        
                    }
                }
                self.performSegueWithIdentifier("BackHome", sender: AnyObject?())
            }
            
            
            
            alert.dismissViewControllerAnimated(true, completion: nil)
            
            
        }))
        
        alert.addAction(UIAlertAction(title: "Annuler", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    
    
    func doPost(){
        postImage.image = imageToShow.image
        postProfil.image = imageProfilToShow.image
        postProfil.layer.cornerRadius = 0.5 * postProfil.bounds.size.width
        
        if isConnectedToNetwork(){
            contentView.alpha = 1
            noInternetLabel.alpha = 0
            getLikes()
            getComments()
            var query = PFQuery(className: "Post")
            query.whereKey("objectId", equalTo: idToFind)
            query.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]?, error: NSError?) -> Void in
                
                if error == nil {
                    if let objects = objects as? [PFObject] {
                        for object in objects {
                            self.songName.text = object.valueForKey("songName") as? String
                            self.songName.accessibilityLabel = "Chanson : \(self.songName.text!)"
                            self.artistName.text = object.valueForKey("artistName") as? String
                            self.artistName.accessibilityLabel = "Artiste : \(self.artistName.text!)"
                            self.postDescription.text = object.valueForKey("postDescription") as? String
                            self.postDescription.accessibilityLabel = "Description de la publication : \(self.postDescription.text!)"
                            
                            
                            var place = object.valueForKey("location") as? String
                            if place == "noLocalisation"{
                                self.postPlace.text = "Inconnu"
                                self.postPlace.accessibilityLabel = "Publié depuis une position inconnue"
                            }else{
                                self.postPlace.text = place
                                self.postPlace.accessibilityLabel = "Publié depuis \(self.postPlace.text!)"
                            }
                            
                            
                            var lastActive: AnyObject? = object.valueForKey("createdAt")
                            self.postDate.text = makeDate(lastActive!)
                            self.postDate.accessibilityLabel = "Publié il y  \(self.postDate.text!)"
                            self.authorId = (object.valueForKey("userID") as? String)!
                            
                            if self.authorId != PFUser.currentUser()?.objectId{
                                self.deleteButton.alpha=0
                            }
                            
                            
                            
                            if object.valueForKey("previewLink") as? String == "noPreview" {
                                self.playButton.enabled = false
                                self.itunesButton.alpha = 0
                                self.infoHeight.constant = 58
                                
                            }else{
                                self.previewLink = (object.valueForKey("previewLink") as? String)!
                                self.itunesLink = (object.valueForKey("itunesLink") as? String)!
                                if playerCurrentSong == self.songName.text || playerCurrentSong == "Titre du morceau"{
                                    self.previewSlider.alpha = 1
                                }
                                
                                self.playButton.alpha = 1
                                
                                if playerIsPaused == false && playerCurrentSong == self.songName.text{
                                    var pauseImage = UIImage(named: "pauseIcon")
                                    self.playButton.setImage(pauseImage, forState: UIControlState.Normal)
                                    self.playButton.setTitle("Mettre l'extrait en pause", forState: UIControlState.Normal)
                                    playerIsPlaying = true;
                                }
                            }
                            self.getAuthor()
                        }
                    }
                    
                } else {
                    println("Error: \(error!) \(error!.userInfo!)")
                }
            }
        }else{
            contentView.alpha = 0.3
            noInternetLabel.alpha = 1
            error = "noInternet"
            showError(self,error,erreurBar)
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(4.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
            songName.text = "Erreur"
            artistName.text = "Erreur"
            postDate.text = "Erreur"
            profilName.setTitle("Erreur réseau", forState: UIControlState.Normal)
            profilName.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            postDescription.text = "Erreur réseau, impossible de récupérer les données !"
            
        }
        
        
        
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doPost()
        
        let playerHasDonePlaying: Void = NSNotificationCenter.defaultCenter().addObserver(self , selector: "resetPlayer:" , name: MPMoviePlayerPlaybackDidFinishNotification , object: nil)
        
        refresher.addTarget(self, action: "refreshData", forControlEvents: UIControlEvents.ValueChanged)
        contentView.addSubview(refresher)
        
        
        var timer = NSTimer()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: Selector("updateSlider:"), userInfo: nil, repeats: true)
        
        makeNotifLabel(self, notificationIcon)
        getNotif()
    }
    
    override func viewDidAppear(animated: Bool) {
        getLikes()
        getComments()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showComments"{
            var secondView: CommentairesViewController = segue.destinationViewController as! CommentairesViewController
            
            
            secondView.idToFind = idToFind
            
        }
        
        if segue.identifier == "ShowUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = PFUser.currentUser()?.username
        }
        
        if segue.identifier == "ShowUserProfilPublic" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = profilName.titleLabel?.text
        }
        
        if segue.identifier == "ShowLikes"{
            
            var secondView: UserCountViewController = segue.destinationViewController as! UserCountViewController
            secondView.idToFind = idToFind
            secondView.typeToGet = "likes"
            
        }
        
        
    }
    
    
    
    
    
    
    
}
