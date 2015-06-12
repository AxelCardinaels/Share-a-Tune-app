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
    
    
//-------------- Gestion du rafraichissement -----------------//
    
    var refresher : UIRefreshControl = UIRefreshControl()
    
    func refreshData(){
        
        getOrderedPosts()
        self.refresher.endRefreshing()
    }
    
    
//-------------- Déclarations des variables/fonctions pour la gestion des erreurs -----------------//
    
    @IBOutlet var erreurBar: UILabel!
    @IBOutlet var noInternetLabel: UILabel!
    @IBOutlet var noPostLabel: UILabel!
    
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    
//-------------- Déclarations des variables pour les informations d'utilisateurs + Posts -----------------//
    
    
    @IBOutlet var notificationIcon: UIBarButtonItem!
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
    var likes = [String : String]()
    var comments = [String: String]()
    
    
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
            noPostLabel.alpha = 0
            noInternetLabel.alpha = 0
            var me = PFUser.currentUser()
            var username = me?.valueForKey("username") as! String
            actualUserID = (me!.valueForKey("objectId") as? String)!
            userStock.append(me!)
            makeSettingsButton()
            
            var profilPictureFile: AnyObject? = me!.objectForKey("profilePicture")
            
            if me!.valueForKey("bio") as! String == "noBio" || me!.valueForKey("bio") as! String == "" {
                profilDescription.text = "Cet utilisateur n'a pas encore de description... Il aime peut être sembler mystérieux ?"
                profilDescription.accessibilityLabel = "Description de l'utilisateur : Cet utilisateur n'a pas encore de description... Il aime peut être sembler mystérieux ?"
            }else{
                var bio = me!.valueForKey("bio") as! String
                profilDescription.text = bio
                profilDescription.accessibilityLabel = "Description de l'utilisateur : \(bio)"
                
            }
            
            if error == ""{
                getFollowers()
                getFollowing()
                getOrderedPosts()
                noPostLabel.alpha = 0
                noInternetLabel.alpha = 0
                
                profilPictureFile!.getDataInBackgroundWithBlock { (imageData , imageError ) -> Void in
                    
                    if imageError == nil{
                        let image = UIImage(data: imageData!)
                        self.profilPicture.image = image
                        self.profilPicture.accessibilityLabel = "Photo de profil de l'utilisateur \(username)"
                    }
                }
            }

            
        }else{
            
            if error == ""{
                noPostLabel.alpha = 0
                noInternetLabel.alpha = 0
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
                            var username = me.valueForKey("username") as! String
                            
                            var profilPictureFile: AnyObject? = me.objectForKey("profilePicture")
                            
                            if me.valueForKey("bio") as! String == "noBio" || me.valueForKey("bio") as! String == "" {
                                self.profilDescription.text = "Cet utilisateur n'a pas encore de description... Il aime peut être sembler mystérieux ?"
                            }else{
                                var bio = me.valueForKey("bio") as! String
                                self.profilDescription.text = bio
                                self.profilDescription.accessibilityLabel = "Description de l'utilisateur : \(bio)"
                            }
                            
                            profilPictureFile!.getDataInBackgroundWithBlock { (imageData , imageError ) -> Void in
                                
                                if imageError == nil{
                                    let image = UIImage(data: imageData!)
                                    self.profilPicture.image = image
                                    self.profilPicture.accessibilityLabel = "Photo de profil de l'utilisateur \(username)"
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
                println("Fail Check follow")
            }
        }
    }
    
    
//-------------- Function pour suivre un utilisateur -----------------//
    
    func followUser(){
        var following = PFObject(className: "Followers")
        following["follower"] = PFUser.currentUser()?.objectId
        following["following"] = actualUserID
        following.saveInBackground()
        following.saveInBackgroundWithBlock { (saved, error) -> Void in
            if saved != false{
                self.getFollowers()
                self.makeUnfollowButton()
            }
        }
        
        
        
        var notification = PFObject(className: "Notifications")
        notification["postId"] = "follow"
        notification["authorId"] = actualUserID
        notification["likerId"] = PFUser.currentUser()?.objectId
        notification["notificationType"] = "follow"
        notification["sawNotif"] = false
        notification["clickNotif"] = false
        notification.saveInBackground()
         
        

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
                    self.makeFollowButton()
                    self.getFollowers()
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
                self.post.removeAll(keepCapacity: true)
                self.likes.removeAll(keepCapacity: true)
                self.comments.removeAll(keepCapacity: true)
                if let objects = objects as? [PFObject] {
                    
                    if objects.count == 0{
                        self.noPostLabel.alpha = 1
                    }
                    
                    for object in objects {
                        self.post.append(object)
                        var idToFind = object.objectId
                        self.getLikes(idToFind!)
                        self.getComments(idToFind!)
                    }
                }
                
                self.feedTable.reloadData()
            } else {
                // Log details of the failure
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
    }
    
//-------------- Récupération du nombre de j'aime d'un post -----------------//
    
    func getLikes(idToFind : String){
        
        var query = PFQuery(className: "Likes")
        query.whereKey("postId", equalTo:idToFind)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [PFObject] {
                    
                    self.likes.updateValue("\(objects.count) j'aime", forKey: idToFind)
                }
                
                self.feedTable.reloadData()
            } else {
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
    }
    
    //-------------- Récupération du nombre de commentaires d'un post -----------------//
    
    func getComments(idToFind : String){
        
        var query = PFQuery(className: "Comments")
        query.whereKey("postId", equalTo:idToFind)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [PFObject] {
                    
                    self.comments.updateValue("\(objects.count) avis", forKey: idToFind)
                }
                
                self.feedTable.reloadData()
            } else {
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
    }
    
//-------------- Suppression d'un post -----------------//
    
    @IBAction func PostDeleteAlert(sender: AnyObject) {
        
        var positionButton = sender.convertPoint(CGPointZero, toView: self.feedTable)
        var indexPath = self.feedTable.indexPathForRowAtPoint(positionButton)
        var rowIndex = indexPath!.row
        var postId = post[rowIndex].valueForKey("objectId") as! String

        
        var alert = UIAlertController(title: nil, message: "Êtres vous sur de vouloir supprimer cette publication ?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        
        alert.addAction(UIAlertAction(title: "Supprimer la publication", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            var query = PFQuery(className:"Post")
            query.whereKey("objectId", equalTo: postId)
            query.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]?, error: NSError?) -> Void in
                
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        object.deleteInBackground()
                        
                    }
                }
                self.getOrderedPosts()
            }
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
            
        }))
        
        alert.addAction(UIAlertAction(title: "Annuler", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
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
        performSegueWithIdentifier("userSettings", sender: self)
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
        
        //Mise en place du refresh
        refresher.addTarget(self, action: "refreshData", forControlEvents: UIControlEvents.ValueChanged)
        feedTable.addSubview(refresher)
        
        makeNotifLabel(self, notificationIcon)
        getNotif()
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        initialisePlayer(playerView, playerSong, playerArtist, feedTable)
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
        return post.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("postCell", forIndexPath: indexPath) as! PostTableViewCell
        
        //On récupère le post en fonction de l'index de la céllule actuelle
        
        var currentCell = indexPath
        var currentPost = post[indexPath.row]
        var currentUser = userStock[0]
        var currentLikeNumber = likes[currentPost.objectId!]
        var currentCommentNumber = comments[currentPost.objectId!]
        
        //Affiche du nom de l'utilisateur
        
        var daUser = currentUser.valueForKey("username") as? String
        
        cell.username.setTitle(daUser!, forState: UIControlState.Normal)
        cell.username.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        cell.username.accessibilityLabel = "Publié par \(daUser!)"
        
        
        //On calcul la durée entre la date du post et la date actuelle
        
        var lastActive: AnyObject? = currentPost.valueForKey("createdAt")
        cell.postTime.text = makeDate(lastActive!)
        cell.postTime.accessibilityLabel = "Publié il y a \(cell.postTime.text!)"
        
        // On rempli les informations du Post
        
        cell.postArtist.text = currentPost.valueForKey("artistName") as? String
        cell.postArtist.accessibilityLabel = "Artiste : \(cell.postArtist.text!)"
        cell.postDescription.text = currentPost.valueForKey("postDescription") as? String
        cell.postDescription.accessibilityLabel = "Description de la publication : \(cell.postDescription.text!)"
        cell.postTitle.text = currentPost.valueForKey("songName") as? String
        cell.postTitle.accessibilityLabel = "Chanson : \(cell.postTitle.text!)"
        
        cell.likesButton.setTitle(currentLikeNumber, forState: UIControlState.Normal)
        cell.commentsButton.setTitle(currentCommentNumber, forState: UIControlState.Normal)
        
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
            cell.postPlay.hidden = false
            cell.postPlay.enabled = false
            cell.postPlay.alpha = 0.7
        }else{
            cell.postPlay.hidden = false;
            cell.postPlay.enabled = true
            cell.postPlay.alpha = 1
            cell.postPlay.addTarget(self, action: "getPreview:", forControlEvents: .TouchUpInside)
        }
        
        //On check si le post à une localisation , si oui, on l'affiche
        
        if currentPost.valueForKey("location") as? String == "noLocalisation" {
            cell.postLocation.text = "Inconnu"
            cell.postLocation.accessibilityLabel = "Publié depuis une position inconnue"
        }else{
            cell.postLocation.text = currentPost.valueForKey("location") as? String
            cell.postLocation.accessibilityLabel = "Publié depuis \(cell.postLocation.text!)"
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
        
        //Si l'id d'utilisateur actuelle correspond à celle de l'utilisateur loggé, on affiche l'option pour supprimer un post
        
        if PFUser.currentUser()?.objectId == currentUser.objectId {
            cell.postDelete.alpha = 1
        }
        

        
        return cell;
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
        if segue.identifier == "ShowUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = PFUser.currentUser()?.username
        }
        
        if segue.identifier == "showDetailPublication"{
            
            var secondView: SingleProjectViewController = segue.destinationViewController as! SingleProjectViewController
            var positionButton = sender!.convertPoint(CGPointZero, toView: self.feedTable)
            var indexPath = self.feedTable.indexPathForRowAtPoint(positionButton)
            var rowIndex = indexPath?.row
            var theCell = feedTable.cellForRowAtIndexPath(indexPath!)
            var imageContainer = theCell?.valueForKey("postPicture") as? UIImageView
            var profilContainer = theCell?.valueForKey("userProfil") as? UIImageView
            
            secondView.idToFind = post[rowIndex!].valueForKey("objectId") as! String
            
            if imageContainer != nil {
                secondView.imageToShow = imageContainer!
                secondView.imageProfilToShow = profilContainer!
            }
            
            
        }
        
        if segue.identifier == "showComments"{
            var secondView: CommentairesViewController = segue.destinationViewController as! CommentairesViewController
            var positionButton = sender!.convertPoint(CGPointZero, toView: self.feedTable)
            var indexPath = self.feedTable.indexPathForRowAtPoint(positionButton)
            var rowIndex = indexPath?.row
            var theCell = feedTable.cellForRowAtIndexPath(indexPath!)
            
            secondView.idToFind = post[rowIndex!].valueForKey("objectId") as! String
            
        }
        
        if segue.identifier == "ShowLikes"{
            
            var secondView: UserCountViewController = segue.destinationViewController as! UserCountViewController
            var positionButton = sender!.convertPoint(CGPointZero, toView: self.feedTable)
            var indexPath = self.feedTable.indexPathForRowAtPoint(positionButton)
            var rowIndex = indexPath?.row
            var theCell = feedTable.cellForRowAtIndexPath(indexPath!)
            secondView.idToFind = post[rowIndex!].valueForKey("objectId") as! String
            secondView.typeToGet = "likes"
            
        }
        
        if segue.identifier == "ShowFollowers" {
            var secondView: UserCountViewController = segue.destinationViewController as! UserCountViewController
            secondView.idToFind = actualUserID
            secondView.typeToGet = "followers"
            secondView.title = "Abonné à \(self.title!)"
        }
        
        if segue.identifier == "ShowFollowing" {
            var secondView: UserCountViewController = segue.destinationViewController as! UserCountViewController
            secondView.idToFind = actualUserID
            secondView.typeToGet = "following"
            secondView.title = "Suivi par \(self.title!)"
        }
        
        
    }
    
    
    
}
