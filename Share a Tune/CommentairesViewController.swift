//
//  CommentairesViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 10/06/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import MediaPlayer
import SystemConfiguration

class CommentairesViewController: UIViewController, UITextViewDelegate {
    
    
    @IBOutlet var textZoneHeigt: NSLayoutConstraint!
    @IBOutlet var textZone: UITextView!
    @IBOutlet var viewContrain: NSLayoutConstraint!
    @IBOutlet var commentTable: UITableView!
    var idToFind = String()
    var height = CGFloat()
    var postAuthor : String = ""
    
    @IBOutlet var postButton: UIButton!
    var comments = [PFObject]()
    var commentsUser = [String : PFObject]()
    var userList = [String]()
    
    var refresher : UIRefreshControl = UIRefreshControl()
    
    func refreshData(){
        
        getComments()
        self.refresher.endRefreshing()
    }
    
    @IBOutlet var erreurBar: UILabel!
    @IBOutlet var noInternetLabel: UILabel!
    
    var error = ""
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    
    
    func quitKeyboard(sender: AnyObject){
        viewContrain.constant=0
    }
    
    //Ajout d'événement pour le clavier ( Apparait , disparait)
    
    func registerForKeyboardNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self,selector: "keyboardWillBeShown:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // La vue remonte quand le clavier apparait
    func keyboardWillBeShown(sender: NSNotification) {
        let info: NSDictionary = sender.userInfo!
        let value: NSValue = info.valueForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
        
        let keyboardSize: CGSize = value.CGRectValue().size
        
        
        viewContrain.constant = self.view.frame.size.height - value.CGRectValue().origin.y
        
    }
    
    // la vue se remet en place quand le clavier disparait
    func keyboardWillBeHidden(sender: NSNotification) {
        viewContrain.constant = 0
    }
    
    func textViewDidChange(textView: UITextView) {
        textZoneHeigt.constant = textView.contentSize.height + 20
        
        if textZone.text == nil || textZone.text == "Votre commentaire" {
            postButton.enabled = false
        }else{
            postButton.enabled = true;
        }
    }

    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == "Votre commentaire" {
            textView.text = nil
        }
    }
    

    
    //Check pour remettre le placeholder en place ou pas
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Votre commentaire"
        }
    }
    

    
    func findAuthor(){
        
        if postAuthor == "" {
            var query = PFQuery(className: "Post")
            query.whereKey("objectId", equalTo:idToFind)
            query.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]?, error: NSError?) -> Void in
                if error == nil {
                    
                    if let objects = objects as? [PFObject] {
                        
                        for object in objects {
                            
                            self.postAuthor = (object.valueForKey("userID") as? String)!
                        }
                    }
                    
                } else {
                    println("Error: \(error!) \(error!.userInfo!)")
                }
            }
        }
     
    }
    
    func getComments(){
        
        if isConnectedToNetwork() {
            noInternetLabel.alpha = 0
            commentTable.alpha = 1
            findAuthor()
            var query = PFQuery(className: "Comments")
            query.whereKey("postId", equalTo:idToFind)
            query.orderByAscending("updatedAt")
            query.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]?, error: NSError?) -> Void in
                if error == nil {
                    self.comments.removeAll(keepCapacity: true)
                    self.userList.removeAll(keepCapacity: true)
                    if let objects = objects as? [PFObject] {
                        
                        for object in objects {
                            
                            self.comments.append(object)
                            var posterId = object.valueForKey("posterId") as? String
                            self.userList.append(posterId!)
                            
                        }
                    }
                    
                    self.getUsers()
                    self.commentTable.reloadData()
                    
                    if self.comments.count > 0 {
                       self.commentTable.scrollToRowAtIndexPath(NSIndexPath(forRow: self.comments.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
                    }
                    
                    
                } else {
                    self.error = ""
                    showError(self,self.error,self.erreurBar)
                    var timer = NSTimer()
                    timer = NSTimer.scheduledTimerWithTimeInterval(4.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
                }
            }
        }else{
            noInternetLabel.alpha = 1
            commentTable.alpha = 0.5
            error = "noInternet"
            showError(self,error,erreurBar)
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(4.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
        }
        
      
        
        
        
    }
    
    func getUsers(){
        var query = PFUser.query()
        query?.whereKey("objectId", containedIn: userList)
        query!.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                self.commentsUser.removeAll(keepCapacity: true)
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        var posterId = object.objectId
                        
                        self.commentsUser.updateValue(object, forKey: posterId!)
                    }
                }
                self.commentTable.reloadData()
            } else {
                println("Error: \(error!) \(error!.userInfo!)")
            }
        }
        
    }
    
    
    @IBAction func postComment(sender: AnyObject) {
        
        if count(textZone.text) != 0 || textZone.text != "Votre commentaire" {
            var comment = PFObject(className: "Comments")
            comment["postId"] = idToFind
            comment["posterId"] = PFUser.currentUser()?.objectId
            comment["comment"] = textZone.text
            comment.saveInBackgroundWithBlock { (saved, error) -> Void in
                if saved != false{
                    self.textZone.text = "Votre commentaire"
                    self.getComments()
                }
            }
            
            if postAuthor != PFUser.currentUser()?.objectId{
                var notification = PFObject(className: "Notifications")
                notification["postId"] = idToFind
                notification["authorId"] = postAuthor
                notification["likerId"] = PFUser.currentUser()?.objectId
                notification["notificationType"] = "comment"
                notification["sawNotif"] = false
                notification["clickNotif"] = false
                notification.saveInBackground()
            }
            
            
            self.view.endEditing(true);
        }
        
        
        
        
    }

    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true);
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForKeyboardNotifications()
        getComments()
        
        refresher.addTarget(self, action: "refreshData", forControlEvents: UIControlEvents.ValueChanged)
        commentTable.addSubview(refresher)
        
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
        return comments.count
    }

    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("commentCell", forIndexPath: indexPath) as! CommentTableViewCell
        
        var actualComment = comments[indexPath.row]
        var actualUser = commentsUser[(actualComment.valueForKey("posterId") as? String)!]
        
        var username = actualUser?.valueForKey("username") as? String
        
        if username != nil {
           cell.cellName.setTitle("\(username!)", forState: UIControlState.Normal) 
        }
        
        
        cell.cellName.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        cell.cellText.text = actualComment.valueForKey("comment") as? String
        
        cell.profilPicture.layer.cornerRadius = 0.5 * cell.profilPicture.bounds.size.width
        if actualUser?.valueForKey("profilePicture")! != nil{
            var pictureFile: AnyObject? = actualUser?.valueForKey("profilePicture")!
            pictureFile!.getDataInBackgroundWithBlock({ (imageData, error) -> Void in
                var theImage = UIImage(data: imageData!)
                cell.profilPicture.image = theImage
            })
        }
        
        cell.cellText.sizeToFit()
        height = cell.cellText.frame.height + 54
        return cell;
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return height
    }
    
    
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowUserProfil" {
            var secondView: UserProfilViewController = segue.destinationViewController as! UserProfilViewController
            var positionButton = sender!.convertPoint(CGPointZero, toView: self.commentTable)
            var indexPath = self.commentTable.indexPathForRowAtPoint(positionButton)
            var theCell = commentTable.cellForRowAtIndexPath(indexPath!)
            
            var theName: AnyObject = sender?.currentTitle! as! AnyObject
            
            secondView.title = theName as? String
        }
    }
    

    
    
    
    
}
