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

class UserSearchViewController: UIViewController, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate {
    
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    @IBOutlet var erreurBar: UILabel!
    
    var users = [""]
    var profilePictures = [UIImage]()
    var profilePicturesFiles = [PFUser.currentUser()?.objectForKey("profilePicture")!]
    var error = ""
    
    var searchBar = UISearchBar()
    
    @IBOutlet var tableUsers: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        //Mise en place de la barre de recherche dans la bar de navigation
        
        var colorTextSearchBar = searchBar.valueForKey("searchField") as? UITextField
        colorTextSearchBar?.textColor = UIColor.whiteColor()
        searchBar.sizeToFit()
        searchBar.searchBarStyle = UISearchBarStyle.Minimal
        //searchBar.setShowsCancelButton(true, animated: true)
        searchBar.placeholder = "Rechercher un utilisateur"
        self.navigationItem.titleView = searchBar
        
        //Remplissage du tableau
        
        var query = PFUser.query()
        query?.findObjectsInBackgroundWithBlock({ (objects , findError : NSError?) -> Void in
            
            if objects != nil{
                self.users.removeAll(keepCapacity: true)
                self.profilePictures.removeAll(keepCapacity: true)
                self.profilePicturesFiles.removeAll(keepCapacity: true)
                
                for object in objects! {
                    var user:PFUser = object as! PFUser
                    
                    if user.username != PFUser.currentUser()?.username{
                        self.profilePicturesFiles.append(user.valueForKey("profilePicture") as! PFFile)
                        self.users.append(user.username!)
                    }
                    
                    
                    
                }
                
                self.tableUsers.reloadData()
            }else{
                self.error = "noUsers"
                showError(self, self.error, self.erreurBar)
                var timer = NSTimer()
                timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
            }
            
        })
        
        
        
        
        // Do any additional setup after loading the view.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1;
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return users.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("userCell", forIndexPath: indexPath) as! UsersTableViewCell
        
        
        cell.imageCell.layer.cornerRadius = 0.5 * cell.imageCell.bounds.size.width
        cell.labelCell.text = users[indexPath.row]
        
        profilePicturesFiles[indexPath.row]!.getDataInBackgroundWithBlock { (imageData , imageError ) -> Void in
            
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
        
        
        
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
