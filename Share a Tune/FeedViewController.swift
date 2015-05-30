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
    
    
    
    //-------------- Gestion du rafraichissement -----------------//
    
    var refresher : UIRefreshControl = UIRefreshControl()
    
    func refreshData(){

        getFollowedList()
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
    
    
//-------------- Déclarations des variables utiles pour followers, posts (feed en somme) -----------------//
    
    @IBOutlet var feedTable: UITableView!
    
    var followed = [String]()
    var post = [PFObject]()
    var followedInfo = [String : PFObject]()
    
    
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
    
    
    
//-------------- Récupération des followers -----------------//
    
    func getFollowedList(){
        
        var error = ""
        
        if isConnectedToNetwork() == false{
            error = "noInternet"
        }
        
        if error == ""{
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
                    println("Error: \(error!) \(error!.userInfo!)")
                }
            }
        }else{
            showError(self,error,erreurBar)
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(4.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
            noInternetLabel.alpha = 1
        }
        
    }
    
    
    
//-------------- Récupération des infos des followers -----------------//
    
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
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        
                        self.followedInfo.updateValue(object, forKey: idUser)
                    }
                }
                
            } else {
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
        
    }
    
    
    
//-------------- Récupération de la liste des posts par ordre chronologique -----------------//
    
    func getOrderedPosts(){
        
        var query = PFQuery(className:"Post")
        query.whereKey("userID", containedIn: followed)
        query.orderByDescending("createdAt")
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
        
            if error == nil {
                
                self.post.removeAll(keepCapacity: true)
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
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
    }
    
    
//-------------- Suppression d'un post -----------------//
    
    @IBAction func deletePostAlert(sender: AnyObject) {
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


    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //On affiche la bar de navigation
        self.navigationController?.navigationBarHidden = false;
        
        //Initialisation du player
        
        initialisePlayer(playerView, playerSong, playerArtist, feedTable)
        
        let playerHasDonePlaying: Void = NSNotificationCenter.defaultCenter().addObserver(self , selector: "hidePlayer:" , name: MPMoviePlayerPlaybackDidFinishNotification , object: nil)
        
        //Lancement de la fonction pour récupérer la liste des Users à afficher + leurs posts
        
        getFollowedList()
        
        //Mise en place du refresh
        refresher.addTarget(self, action: "refreshData", forControlEvents: UIControlEvents.ValueChanged)
        feedTable.addSubview(refresher)
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
        var currentUser = followedInfo[currentPost.valueForKey("userID") as! String]
        
        //Affiche du nom de l'utilisateur
        cell.username.setTitle(currentUser?.valueForKey("username") as? String, forState: UIControlState.Normal)
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
        if currentUser?.valueForKey("profilePicture")! != nil{
            var pictureFile: AnyObject? = currentUser?.valueForKey("profilePicture")!
            pictureFile!.getDataInBackgroundWithBlock({ (imageData, error) -> Void in
                var theImage = UIImage(data: imageData!)
                cell.userProfil.image = theImage
            })
        }
        
        //Si l'id d'utilisateur actuelle correspond à celle de l'utilisateur loggé, on affiche l'option pour supprimer un post
        
        
        if PFUser.currentUser()?.objectId == currentUser?.objectId {
            cell.postDelete.alpha = 1
        }
        
        

        
        return cell;
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        //On récupère le bouton clické et sa valeur ( pseudo de l'utilisateur ). On le passe comme titre de la vue de profil
        
        if segue.identifier == "showUserProfilFeed" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            var positionButton = sender!.convertPoint(CGPointZero, toView: self.feedTable)
            var indexPath = self.feedTable.indexPathForRowAtPoint(positionButton)
            var theCell = feedTable.cellForRowAtIndexPath(indexPath!)
            
            var theName: AnyObject = sender?.currentTitle! as! AnyObject
            
            secondView.title = theName as? String
        }
        
        //Si on clique sur l'icone du profil, le titre du profil est l'username de l'utilisateur actual
        
        if segue.identifier == "ShowUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = PFUser.currentUser()?.username
        }
    }
    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    
    

}
