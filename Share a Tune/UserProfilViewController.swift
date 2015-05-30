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
import MediaPlayer

class UserProfilViewController: UIViewController, UITableViewDelegate {
    
//-------------- Déclarations des variables/fonctions pour la gestion des erreurs -----------------//
    
    @IBOutlet var erreurBar: UILabel!
    @IBOutlet var noInternetLabel: UILabel!
    @IBOutlet var noPostLabel: UILabel!
    
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    
//-------------- Déclarations des variables pour les informations d'utilisateurs + Posts -----------------//
    
    @IBOutlet var followingCount: UIButton!
    @IBOutlet var followerCount: UIButton!
    @IBOutlet var feedTable: UITableView!
    @IBOutlet var theView: UIView!
    @IBOutlet var profilPicture: UIImageView!
    @IBOutlet var profilDescription: UILabel!
    var actualUserID = ""
    var following = [String]()
    var followers = [String]()
    var post = [PFObject]()
    var userStock = [PFObject]()
    
    
//-------------- Déclaration de la fonction générant le profil -----------------//
    
    func doProfil(myself : Bool){
        
        var error = ""
        
        if isConnectedToNetwork() == false{
            noInternetLabel.alpha = 1
            error = "noInternet"
            showError(self,error,erreurBar)
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(4.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
            
        }
        
        if myself == true{
            var me = PFUser.currentUser()
            actualUserID = (me!.valueForKey("objectId") as? String)!
            userStock.append(me!)
            makeSettingsButton()
            
            var profilPictureFile: AnyObject? = me!.objectForKey("profilePicture")
            
            if me!.valueForKey("bio") as! String == "noBio"{
                profilDescription.text = "Cet utilisateur n'a pas encore de description... Il aime peut être sembler mystérieux ?"
            }else{
                profilDescription.text = me!.valueForKey("bio") as? String
            }
            
            if error == ""{
                getFollowers()
                getFollowing()
                getOrderedPosts()
                
                profilPictureFile!.getDataInBackgroundWithBlock { (imageData , imageError ) -> Void in
                    
                    if imageError == nil{
                        let image = UIImage(data: imageData!)
                        self.profilPicture.image = image
                    }
                }
            }

            
        }else{
            
            if error == ""{
                var query = PFUser.query()
                query?.whereKey("username", equalTo: self.title!)
                query!.findObjectsInBackgroundWithBlock {
                    (objects: [AnyObject]?, error: NSError?) -> Void in
                    
                    if let objects = objects as? [PFObject] {
                        for object in objects {
                            
                            self.actualUserID = object.objectId! as String
                            self.userStock.append(object)
                            self.checkIfFollow()
                            self.getFollowers()
                            self.getFollowing()
                            self.getOrderedPosts()
                            
                            
                            var me = object
                            
                            var profilPictureFile: AnyObject? = me.objectForKey("profilePicture")
                            
                            if me.valueForKey("bio") as! String == "noBio"{
                                self.profilDescription.text = "Cet utilisateur n'a pas encore de description... Il aime peut être sembler mystérieux ?"
                            }else{
                                self.profilDescription.text = me.valueForKey("bio") as? String
                            }
                            
                            profilPictureFile!.getDataInBackgroundWithBlock { (imageData , imageError ) -> Void in
                                
                                if imageError == nil{
                                    let image = UIImage(data: imageData!)
                                    self.profilPicture.image = image
                                }
                            }
                            
                            
                        }
                    }
                }
                
                
            }
            }
            
   
        
    }
    
//-------------- Function pour trouver les followers de l'utilisateur -----------------//
    
    func getFollowers(){
        var query = PFQuery(className: "Followers")
        query.whereKey("following", equalTo: actualUserID)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                self.followers.removeAll(keepCapacity: true)
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        var followedUser: AnyObject? = object.valueForKey("follower")
                        self.followers.append(followedUser! as! String)
                    }
                    self.followerCount.setTitle("\(objects.count) Abonnés", forState: UIControlState.Normal)
                }
            } else {
                // Log details of the failure
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
        
    }
    
//-------------- Function pour trouver les abonnements de l'utilisateur -----------------//
    
    func getFollowing(){
        var query = PFQuery(className: "Followers")
        query.whereKey("follower", equalTo: actualUserID)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                self.following.removeAll(keepCapacity: true)
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        var followedUser: AnyObject? = object.valueForKey("following")
                        self.following.append(followedUser! as! String)
                    }
                    self.followingCount.setTitle("\(objects.count) Abonnements", forState: UIControlState.Normal)
                }
            } else {
                // Log details of the failure
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
        
    }
    
    
    
    
    
//-------------- Check si l'utilisateur follow l'utilisateur actual + Boutons de follow/unfollow -----------------//
    
    //-------------- Check si l'utilisateur connecté si l'utilisateur affiché -----------------//
    
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
    
    
//-------------- Function pour suivre un utilisateur -----------------//
    
    func followUser(){
        var following = PFObject(className: "Followers")
        following["follower"] = PFUser.currentUser()?.objectId
        following["following"] = actualUserID
        following.saveInBackground()
        
        
        makeUnfollowButton()
    }
    
//-------------- Function pour ne plus suivre un utilisateur -----------------//
    
    func unfollowUser(){
        
        var currentUser = PFUser.currentUser()?.objectId
        var query = PFQuery(className:"Followers")
        query.whereKey("follower", equalTo: currentUser!)
        query.whereKey("following", equalTo: actualUserID)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if let objects = objects as? [PFObject] {
                for object in objects {
                    object.deleteInBackground()
                    println("Hello")
                    self.makeFollowButton()
                }
            }
        }
        
    }
    
    //Bouton "Chargement"
    
    func makeLoadingButton(){
        var loadingButton : UIBarButtonItem = UIBarButtonItem(title: "Chargement", style: UIBarButtonItemStyle.Plain, target: self, action: "fakeFollow")
        self.navigationItem.rightBarButtonItem = loadingButton
    }
    
    //Bouton "Suivre"
    
    func makeFollowButton(){
        var followButton : UIBarButtonItem = UIBarButtonItem(title: "Suivre", style: UIBarButtonItemStyle.Plain, target: self, action: "followUser")
        self.navigationItem.rightBarButtonItem = followButton
    }
    
    //Bouton "Suivi"
    
    func makeUnfollowButton(){
        var unfollowButton : UIBarButtonItem = UIBarButtonItem(title: "Suivi", style: UIBarButtonItemStyle.Plain, target: self, action: "unfollowUser")
        self.navigationItem.rightBarButtonItem = unfollowButton
        self.navigationItem.rightBarButtonItem!.tintColor = UIColor.greenColor();
    }
    
    //fonction fake durant le chargement
    
    func fakeFollow(){
        println("Gotcha")
    }
    
//-------------- Récupération de la liste des posts par ordre chronologique -----------------//
    
    func getOrderedPosts(){
        
        var query = PFQuery(className:"Post")
        query.whereKey("userID", equalTo: actualUserID)
        query.orderByDescending("createdAt")
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // The find succeeded.
                println("Successfully retrieved Posts")
                // Do something with the found objects
                if let objects = objects as? [PFObject] {
                    
                    if objects.count == 0{
                        self.noPostLabel.alpha = 1
                    }
                    
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
    
//-------------- Récupération de préview de la partie du tableau + lancement du player -----------------//
    
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
    
    
//-------------- Récupération du lien iTunes Store + ouverture sur le store -----------------//
    
    
    
    func getToStore(sender : AnyObject){
        var positionButton = sender.convertPoint(CGPointZero, toView: self.feedTable)
        var indexPath = self.feedTable.indexPathForRowAtPoint(positionButton)
        var rowIndex = indexPath!.row
        
        var itunesLink = post[rowIndex].valueForKey("itunesLink") as! String
        let url = NSURL(string: itunesLink)
        
        UIApplication.sharedApplication().openURL(url!)
    }
    
//-------------- Créations du bouton + fonction pour modifier le profil -----------------//
    
    func makeSettingsButton(){
        
        var boutonSettings: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        boutonSettings.frame = CGRectMake(0, 0, 35, 35)
        boutonSettings.setImage(UIImage(named:"Parametres"), forState: UIControlState.Normal)
        boutonSettings.addTarget(self, action: "goToSettings:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var rightBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: boutonSettings)
        
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    func goToSettings(sender:UIButton!){
        performSegueWithIdentifier("EditionProfil", sender: self)
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
        stopPlayer(playerView, feedTable)
    }
    
    func hidePlayer(note : NSNotification){
        stopPlayer(playerView, feedTable)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Si l'utilisateur affiché = utilisateur connecté, on supprime le bouton back
        
        if self.title == PFUser.currentUser()?.username {
            self.navigationItem.hidesBackButton = true;
        }
        
        //Arrondissement du bouton ajout de photo + border
        profilPicture.layer.cornerRadius = 0.5 * profilPicture.bounds.size.width
        self.profilPicture.layer.borderWidth = 3.0;
        self.profilPicture.layer.borderColor = UIColor.whiteColor().CGColor
        
        //alignement des boutons de comptage followers et following
        followerCount.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Right
        followingCount.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        
        
        //Détermine quel type de profil à afficher en fonction de l'utilisateur chargé
        
        if self.title == PFUser.currentUser()?.username{
            doProfil(true)
        }else{
            doProfil(false)
        }
        
        //Initialisation du player
        
        initialisePlayer(playerView, playerSong, playerArtist, feedTable)
        
        let playerHasDonePlaying: Void = NSNotificationCenter.defaultCenter().addObserver(self , selector: "hidePlayer:" , name: MPMoviePlayerPlaybackDidFinishNotification , object: nil)
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1;
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return post.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("postCell", forIndexPath: indexPath) as! PostTableViewCell
        
        //On récupère le post en fonction de l'index de la céllule actuelle
        
        var currentCell = indexPath
        var currentPost = post[indexPath.row]
        var currentUser = userStock[0]
        
        //Affiche du nom de l'utilisateur
        
        cell.username.setTitle(currentUser.valueForKey("username") as? String, forState: UIControlState.Normal)
        cell.username.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        
        
        //On calcul la durée entre la date du post et la date actuelle
        
        var lastActive: AnyObject? = currentPost.valueForKey("createdAt")
        cell.postTime.text = makeDate(lastActive!)
        
        // On rempli les informations du Post
        
        cell.postArtist.text = currentPost.valueForKey("artistName") as? String
        cell.postDescription.text = currentPost.valueForKey("postDescription") as? String
        cell.postDescription.sizeToFit()
        cell.postTitle.text = currentPost.valueForKey("songName") as? String
        
        //On récupère l'image du post
        
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
        
        //On check si le post à un lien itunes, si oui, on affiche le bouton
        
        if currentPost.valueForKey("itunesLink") as? String == "noLink" {
            cell.postItunes.hidden = true;
        }else{
            cell.postItunes.hidden = false;
            cell.postItunes.addTarget(self, action: "getToStore:", forControlEvents: .TouchUpInside)
        }
        
        
        //On check si le post à un lien de preview, si oui, on affiche le bouton
        
        if currentPost.valueForKey("previewLink") as? String == "noPreview" {
            cell.postPlay.hidden = true
        }else{
            cell.postPlay.hidden = false;
            cell.postPlay.addTarget(self, action: "getPreview:", forControlEvents: .TouchUpInside)
        }
        
        //On check si le post à une localisation , si oui, on l'affiche
        
        if currentPost.valueForKey("location") as? String == "noLocalisation" {
            cell.postLocation.text = "Inconnu"
        }else{
            cell.postLocation.text = currentPost.valueForKey("location") as? String
        }
        
        
        //On récupère la photo de l'utilisateur et on la rend ronde
        
        cell.userProfil.layer.cornerRadius = 0.5 * cell.userProfil.bounds.size.width
        if currentUser.valueForKey("profilePicture") != nil{
            var pictureFile: AnyObject? = currentUser.valueForKey("profilePicture")!
            pictureFile!.getDataInBackgroundWithBlock({ (imageData, error) -> Void in
                var theImage = UIImage(data: imageData!)
                cell.userProfil.image = theImage
            })
        }
        

        
        return cell;
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
        if segue.identifier == "ShowUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = PFUser.currentUser()?.username
        }
    }
    
    
    
}
