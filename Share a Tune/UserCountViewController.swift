//
//  UserCountViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 12/06/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import MediaPlayer
import Foundation
import SystemConfiguration

class UserCountViewController: UIViewController, UITableViewDelegate {
    
    
    @IBOutlet var usersTable: UITableView!
    var typeToGet : String = ""
    var idToFind : String = ""
    var usersList = [String]()
    var users = [Int : PFObject]()
    
    
    @IBOutlet var erreurBar: UILabel!
    @IBOutlet var noInternetLabel: UILabel!
    var error = ""
    
   
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    
    var refresher : UIRefreshControl = UIRefreshControl()
    
    func refreshData(){
        
        getUsersList()
        self.refresher.endRefreshing()
    }
    
    
    func getUsersList(){
        
        if isConnectedToNetwork(){
            
            noInternetLabel.alpha = 0
            usersTable.alpha = 1
            
            var query = PFQuery(className: "Likes")
            if typeToGet == "likes"{
                query = PFQuery(className: "Likes")
                query.whereKey("postId", equalTo:idToFind)
            }
            
            if typeToGet == "followers"{
                query = PFQuery(className: "Followers")
                query.whereKey("following", equalTo : idToFind)
            }
            
            if typeToGet == "following"{
                query = PFQuery(className: "Followers")
                query.whereKey("follower", equalTo : idToFind)
            }
            
            query.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]?, error: NSError?) -> Void in
                if error == nil {
                    self.usersList.removeAll(keepCapacity: true)
                    if let objects = objects as? [PFObject] {
                        for object in objects {
                            
                            
                            var likerId: AnyObject? = ""
                            
                            if self.typeToGet == "likes"{
                                likerId = object.valueForKey("likerId")
                            }
                            
                            if self.typeToGet == "followers"{
                                likerId = object.valueForKey("follower")
                            }
                            
                            if self.typeToGet == "following"{
                                likerId = object.valueForKey("following")
                            }
                            
                            self.usersList.append(likerId! as! String)
                            
                        }
                    }
                    self.getUsers()
                } else {
                    println("Error: \(error!) \(error!.userInfo!)")
                }
            }

        }else{
            self.error = "noInternet"
            showError(self,error,erreurBar)
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(4.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
            noInternetLabel.alpha = 1
            usersTable.alpha = 0.5
        }
        
}
    
    func getUsers(){
        var actualCount = 0
        var query = PFUser.query()
        query?.whereKey("objectId", containedIn: usersList)
        query?.orderByAscending("username")
        query!.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                self.users.removeAll(keepCapacity: true)
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        var posterId = object.objectId
                        
                        self.users.updateValue(object, forKey: actualCount )
                        actualCount++
                    }
                }
                self.usersTable.reloadData()
            } else {
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getUsersList()
        
        refresher.addTarget(self, action: "refreshData", forControlEvents: UIControlEvents.ValueChanged)
        usersTable.addSubview(refresher)
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1;
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return users.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("userCell", forIndexPath: indexPath) as! UsersTableViewCell
        
        var currentUser = users[indexPath.row]
        var username = currentUser!.valueForKey("username") as? String
        
        if username != nil{
            cell.labelCell.text = username!
            cell.labelCell.accessibilityLabel = "\(username!) à aimé cette publication. Appuyez pour Afficher son profil "
        }
        
        
        cell.imageCell.layer.cornerRadius = 0.5 * cell.imageCell.bounds.size.width
        currentUser?.valueForKey("profilePicture")!.getDataInBackgroundWithBlock { (imageData , imageError ) -> Void in
            
            if imageError == nil{
                let image = UIImage(data: imageData!)
                cell.imageCell.image = image
            }
        }
        
        return cell;
    }
    

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            var indexPath = usersTable.indexPathForSelectedRow()
            var theCell = usersTable.cellForRowAtIndexPath(indexPath!)
            var theName: AnyObject? = theCell?.valueForKey("labelCell")
            var theNameText: AnyObject? = theName?.valueForKey("text")
            
            secondView.title = theNameText as? String
        }
    }
    
}
