//
//  UserSearchViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 12/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration
import MediaPlayer

class UserSearchViewController: UIViewController, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate {
    
    
    
    
    @IBOutlet var notificationIcon: UIBarButtonItem!

//-------------- Gestion du rafraichissement -----------------//    
    
    var refresher : UIRefreshControl = UIRefreshControl()
    
    func refreshData(){
        
        if currentButton == "boutonSuivi"{
            loadFollowedUser()
        }else{
            loadAllUser(false)
        }
        
        self.refresher.endRefreshing()
    }
    
    
//-------------- Gestion du player  -----------------//
    
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
        stopPlayer(playerView, tableUsers)
    }
    
    func hidePlayer(note : NSNotification){
        stopPlayer(playerView, tableUsers)
    }
    
    
//-------------- Mise en places des variables pour les erreurs  -----------------//
    var error = ""
    
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    
    @IBOutlet var erreurBar: UILabel!
    @IBOutlet var noInternetLabel: UILabel!
    @IBOutlet var noUserLabel: UILabel!
    
    
//-------------- Mise en place des actions pour les boutons Suivi / Tous -----------------//
    
    var currentButton = "boutonSuivi"
    
    @IBOutlet var boutonSuivi: UIBarButtonItem!
    @IBOutlet var boutonAll: UIBarButtonItem!
    
    
    @IBAction func followingButton(sender: AnyObject) {
        currentButton = "boutonSuivi"
        boutonSuivi.tintColor = UIColor(red: 114.0/255, green: 0.0/255, blue: 53.0/255, alpha: 1.0)
        boutonAll.tintColor = UIColor(red: 143.0/255, green: 143.0/255, blue: 143.0/255, alpha: 1.0)
        loadFollowedUser()
    }
    
    @IBAction func allButton(sender: AnyObject) {
        currentButton = "boutonAll"
        boutonSuivi.tintColor = UIColor(red: 143.0/255, green: 143.0/255, blue: 143.0/255, alpha: 1.0)
        boutonAll.tintColor = UIColor(red: 114.0/255, green: 0.0/255, blue: 53.0/255, alpha: 1.0)
        loadAllUser(false)
    }
    
//-------------- Récupération de tous les utilisateurs + Recherche d'utilisateurs -----------------//
    
    
    var usersID = [""]
    var followedInfo = [String : PFObject]()
    
    func loadAllUser(doSearch : Bool){
        tableUsers.alpha = 1
        noInternetLabel.alpha = 0
        noUserLabel.alpha = 0
        var actualRow = 0
        if isConnectedToNetwork() == false {
            error = "noInternet"
            noInternetLabel.alpha = 1
        }else{
            var query = PFUser.query()
            query?.orderByAscending("username")
            
            if doSearch == true{
                let searchDown =  searchBar.text.lowercaseString
                query?.whereKey("username", containsString: searchDown)
            }
            
            query?.findObjectsInBackgroundWithBlock({ (objects , findError : NSError?) -> Void in
                
                if objects != nil{
                    self.usersID.removeAll(keepCapacity: true)
                    self.followedInfo.removeAll(keepCapacity: true)
                    for object in objects! {
                        var user:PFUser = object as! PFUser
                        self.usersID.append((object.valueForKey("objectId") as? String)!)
                        var userPosition : String = "\(actualRow)"
                        self.followedInfo.updateValue(user, forKey: userPosition)
                        actualRow = actualRow + 1
                        
                        
                    }
                    
                }else{
                    self.error = "noUsers"
                    showError(self, self.error, self.erreurBar)
                    var timer = NSTimer()
                    timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
                }
                
                self.tableUsers.reloadData()
                
            })
        }
        
        if error != ""{
            showError(self, self.error, self.erreurBar)
            tableUsers.alpha = 0.7
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(4.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
        }
        
    }
    
//-------------- Récupération des utilisateurs suivis -----------------//
    
    func loadFollowedUser(){
        tableUsers.alpha = 1
        noInternetLabel.alpha = 0
        noUserLabel.alpha = 0
        if isConnectedToNetwork() == false {
            error = "noInternet"
            noInternetLabel.alpha = 1
        }else{
            var currentUser = PFUser.currentUser()!.objectId!
            var query = PFQuery(className: "Followers")
            query.whereKey("follower", equalTo: currentUser )
            
            query.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]?, error: NSError?) -> Void in
                
                if error == nil {
                    
                    self.usersID.removeAll(keepCapacity: true)
                    if let objects = objects as? [PFObject] {
                        
                        if objects.count == 0{
                            self.tableUsers.alpha = 0.7
                            self.noUserLabel.alpha = 1
                        }
                        for object in objects {
                            
                            self.usersID.append((object.valueForKey("following") as? String)!)
                            
                        }
                    }
                    
                } else {
                    // Log details of the failure
                    println("Error: \(error!) \(error!.userInfo!)")
                }
                self.tableUsers.reloadData()
                self.getUserInfos()
            }
        }
        
        if error != ""{
            showError(self, self.error, self.erreurBar)
            tableUsers.alpha = 0
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
        }
        
    }
    
//-------------- Récupération des infos des utilisateurs -----------------//
    
    func getUserInfos(){
        
        var actualRow = 0
        var query = PFUser.query()
        query!.whereKey("objectId", containedIn: usersID)
        query!.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        
                        var userPosition : String = "\(actualRow)"
                        self.followedInfo.updateValue(object, forKey: userPosition)
                        actualRow = actualRow + 1
                    }
                }
            } else {
                // Log details of the failure
                println("Error: \(error!) \(error!.userInfo!)")
            }
            self.tableUsers.reloadData()
        }
    }
    
    
    @IBOutlet var tableUsers: UITableView!
    
    
//-------------- Paramètres de la barre de recherche + Fonctions -----------------//
    
    var searchBar = UISearchBar()
    

    
    //Mise en place de l'interface quand on clique sur la barre de recherche
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        
        if searchBar.text == ""{
            boutonSuivi.tintColor = UIColor(red: 143.0/255, green: 143.0/255, blue: 143.0/255, alpha: 1.0)
            boutonSuivi.enabled = false;
            boutonAll.tintColor = UIColor(red: 114.0/255, green: 0.0/255, blue: 53.0/255, alpha: 1.0)
            searchBar.setShowsCancelButton(true, animated: true)
            loadAllUser(false)
            currentButton = "boutonAll"
        }
        
    }
    
    
    //Quand la valeur du champ de recherche change, on lance la rehcerche
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        loadAllUser(true)
    }
    
    
    //On lance la recherche au click sur le bouton "rechercher"
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        loadAllUser(true)
        self.searchBar.endEditing(true);
    }
    
    //Suppression du bouton cancel + bouton suivi activé de nouveau au click sur le bouton annuler de la bar
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.searchBar.endEditing(true);
        searchBar.setShowsCancelButton(false, animated: true)
        boutonSuivi.enabled = true;
    }
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setHidesBackButton(true, animated: true)
        //Mise en place de la barre de recherche dans la bar de navigation
        
        var colorTextSearchBar = searchBar.valueForKey("searchField") as? UITextField
        colorTextSearchBar?.textColor = UIColor.whiteColor()
        searchBar.sizeToFit()
        searchBar.searchBarStyle = UISearchBarStyle.Minimal
        searchBar.placeholder = "Rechercher un utilisateur"
        self.navigationItem.titleView = searchBar
        
        
        searchBar.delegate = self;
        
        
        loadFollowedUser()
        
        // Initialisation du player
        
        initialisePlayer(playerView, playerSong, playerArtist, tableUsers)
        let playerHasDonePlaying: Void = NSNotificationCenter.defaultCenter().addObserver(self , selector: "hidePlayer:" , name: MPMoviePlayerPlaybackDidFinishNotification , object: nil)
        
        //Mise en place du refresh
        refresher.addTarget(self, action: "refreshData", forControlEvents: UIControlEvents.ValueChanged)
        tableUsers.addSubview(refresher)
        
        makeNotifLabel(self, notificationIcon)
        getNotif()
        
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        if currentButton == "boutonSuivi"{
            loadFollowedUser()
        }else{
            loadAllUser(false)
        }
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1;
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return usersID.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("userCell", forIndexPath: indexPath) as! UsersTableViewCell
        
        var currentIndex = "\(indexPath.row)"
        var currentUser = followedInfo[currentIndex]
        
        cell.imageCell.layer.cornerRadius = 0.5 * cell.imageCell.bounds.size.width
        cell.labelCell.text = currentUser?.valueForKey("username") as? String
        if cell.labelCell.text != nil {
           cell.accessibilityLabel = "Appuyez pour afficher le profil de \(cell.labelCell.text!)"
        }
        
        
        currentUser?.valueForKey("profilePicture")!.getDataInBackgroundWithBlock { (imageData , imageError ) -> Void in
            
            if imageError == nil{
                let image = UIImage(data: imageData!)
                cell.imageCell.image = image
            }
        }
        
        return cell;
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            var indexPath = tableUsers.indexPathForSelectedRow()
            var theCell = tableUsers.cellForRowAtIndexPath(indexPath!)
            var theName: AnyObject? = theCell?.valueForKey("labelCell")
            var theNameText: AnyObject? = theName?.valueForKey("text")
            
            secondView.title = theNameText as? String
        }
        
        if segue.identifier == "ShowUserProfilBouton" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            secondView.title = PFUser.currentUser()?.username
        }
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.searchBar.endEditing(true);
    }
    
    
    
}
