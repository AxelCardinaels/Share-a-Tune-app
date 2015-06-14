//
//  ViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 6/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import Parse
import Foundation
import SystemConfiguration
import MediaPlayer

//-------------- Déclarations + Gestions du player Musical pour les fonctions globales -----------------//


var mediaPlayer: MPMoviePlayerController = MPMoviePlayerController()
var playerIsPaused = false
var playerIsPlaying = false
var playerCurrentSong = "Titre du morceau"
var playerCurrentArtist = "Artiste"

func initialisePlayer(playerView : UIView , songLabel : UILabel, artistLabel : UILabel, indentedView : UITableView){
    
    if playerCurrentSong != "Titre du morceau"{
        songLabel.text = playerCurrentSong
        artistLabel.text = playerCurrentArtist
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            playerView.alpha = 0.6
            indentedView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
            
        })
    }
    songLabel.text = playerCurrentSong
    artistLabel.text = playerCurrentArtist
    
    
}

func pausePlayer(pauseButton : UIButton){
    mediaPlayer.pause()
    var playImage = UIImage(named: "playIcon")
    pauseButton.setTitle("Reprendre la Lecture", forState: UIControlState.Normal)
    pauseButton.setImage(playImage, forState: UIControlState.Normal)
    playerIsPaused = true;
    
}

func playPlayer(playButton : UIButton, songLabel : UILabel, artistLabel : UILabel){
    songLabel.text = playerCurrentSong
    artistLabel.text = playerCurrentArtist
    
    mediaPlayer.play()
    var pauseImage = UIImage(named: "pauseIcon")
    playButton.setTitle("Mettre l'extrait en pause", forState: UIControlState.Normal)
    playButton.setImage(pauseImage, forState: UIControlState.Normal)
    playerIsPaused = false
    playerIsPlaying = true;
}

func stopPlayer(playerView : UIView, indentedView : UITableView){
    
    mediaPlayer.stop()
    playerIsPlaying = false;
    playerIsPaused = false;
    
    
    UIView.animateWithDuration(0.4, animations: { () -> Void in
        playerView.alpha = 0
        indentedView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
    })
    
    playerCurrentSong = "Titre du morceau"
    playerCurrentArtist = "Artiste"
    
}

func killPlayer(){
    mediaPlayer.stop()
    playerCurrentSong = "Titre du morceau"
    playerCurrentArtist = "Artiste"
    playerIsPlaying = false
}

func showPlayer(playerView : UIView, indentedView : UITableView){
    
    UIView.animateWithDuration(0.4, animations: { () -> Void in
        playerView.alpha = 0.6
        indentedView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        
    })
}

//-------------- Gestion des erreurs de façon globale -----------------//


var errors = [
    "invalidEmail" : "Merci d'entrer une adresse email valide",
    "takenEmail" : "Cette adresse email est déja utilisée",
    "takenUser" : "Ce nom d'utilisateur est déja utilisé",
    "empty" : "Merci de remplir tous les champs",
    "noInternet" : "Vous n'êtes pas connecté à internet",
    "noSpec" : "Merci de ne pas utiliser de caractères spéciaux",
    "noSpecUser" : "Caractères spéciaux autorisés : '- _ et .'",
    "shortPassword" : "Le mot de passe doit dépasser 6 caractères",
    "shortUsername" : "Le nom d'utilisateur doit dépasser 2 caractères",
    "badLogin" : "Nom d'utilisateur ou Mot de passe incorrect",
    "noVerif" : "Merci de valider votre compte avant de vous connecter",
    "noUsers" : "Impossible de charger les utilisateurs",
    "noSong" : "Et si vous écoutiez de la musique d'abord ?",
    "descriptionTooLong" : "La description est trop longue"
]


//Fonctions pour afficher les erreurs

func showError(vc:UIViewController, error:String, bar:UILabel){
    
    bar.adjustsFontSizeToFitWidth = true;
    
    switch error {
    case "101":
        bar.text = errors["badLogin"]
    case "125":
        bar.text = errors["invalidEmail"]
    case "203":
        bar.text = errors["takenEmail"]
    case "202":
        bar.text = errors["takenUser"]
    case "empty":
        bar.text = errors["empty"]
    case "noInternet":
        bar.text = errors["noInternet"]
    case "noSpec":
        bar.text = errors["noSpec"]
    case "noSpecUser":
        bar.text = errors["noSpecUser"]
    case "shortPassword":
        bar.text = errors["shortPassword"]
    case "shortUsername":
        bar.text = errors["shortUsername"]
    case "noVerif":
        bar.text = errors["noVerif"]
    case "noSong":
        bar.text = errors["noSong"]
    case "noUser":
        bar.text = errors["noUser"]
    case "descriptionTooLong":
        bar.text = errors["descriptionTooLong"]
        
        
    default:
        bar.text = "Oups, Erreur inconnue"
    }
    
    
    
    UIView.animateWithDuration(0.8, animations: { () -> Void in
        bar.alpha = 1.0
    })
    
    
}

var time:Bool = false;

func errorFade(time : Bool, bar : UILabel){
    if time == true{
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            var daBar: UILabel = bar
            daBar.alpha = 0
            
        })
    }
    
}

//-------------- Check divers -----------------//


// check pour savoir si un appareil photo est dispo

var isCamera = UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice(rawValue: 0)!)

//Fonction pour checker si internet est présent

func isConnectedToNetwork() -> Bool {
    
    var Status:Bool = false
    let url = NSURL(string: "http://google.com/")
    let request = NSMutableURLRequest(URL: url!)
    request.HTTPMethod = "HEAD"
    request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData
    request.timeoutInterval = 10.0
    
    var response: NSURLResponse?
    
    var data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: nil) as NSData?
    
    if let httpResponse = response as? NSHTTPURLResponse {
        if httpResponse.statusCode == 200 {
            Status = true
        }
    }
    
    return Status
}


//-------------- Gestion du loading sign pour un bouton -----------------//

var activityIndicatorButton = UIActivityIndicatorView()
var activityButtonText = "";

func activityIndicatorButtonMake(button:UIButton){
    
    activityIndicatorButton = UIActivityIndicatorView(frame: CGRectMake(0, 0, 25, 25))
    activityIndicatorButton.center = button.center
    activityIndicatorButton.hidesWhenStopped = true
    activityIndicatorButton.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
    activityIndicatorButton.startAnimating()
    button.setTitle("", forState: UIControlState.Normal)
    UIApplication.sharedApplication().beginIgnoringInteractionEvents()
}

func activityIndicatorHeaderMake() -> UIActivityIndicatorView{
    
    activityIndicatorButton = UIActivityIndicatorView(frame: CGRectMake(0, 0, 25, 25))
    activityIndicatorButton.hidesWhenStopped = true
    activityIndicatorButton.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
    activityIndicatorButton.startAnimating()
    UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    return activityIndicatorButton
}



func activityIndicatorButtonKill(button:UIButton){
    button.setTitle(activityButtonText, forState: UIControlState.Normal)
    activityIndicatorButton.stopAnimating()
    UIApplication.sharedApplication().endIgnoringInteractionEvents()
}




//-------------- Gestion du calcul de temps entre la date d'un post et la date actuelle -----------------//


func makeDate(postdate : AnyObject) -> String{
    
    var finalTime = ""
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'-'HH':'mm':'ss"
    var postDate = dateFormatter.stringFromDate(postdate as! NSDate)
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
                finalTime = "< 1Min"
                
            }else{
                finalTime = "\(components.minute)Min"
            }
            
        }else{
            finalTime = "\(components.hour)h"
        }
        
    }else{
        finalTime = "\(components.day)j"
    }
    return finalTime
}


//-------------- Gestion de la pastille de notification -----------------//



var notifNumber : Int = 0
var actualNotifNumber : Int = 0
var notifLabel = UILabel()

func makeNotifLabel(vc : UIViewController, icon : UIBarButtonItem){
    var view: AnyObject? = icon.valueForKey("view")
    notifLabel = UILabel(frame : CGRect(x: view!.frame.origin.x, y: view!.frame.origin.y, width: 25,height: 25))
    notifLabel.center = CGPointMake(view!.frame.origin.x + 20 , vc.view.frame.height - 40 )
    notifLabel.textColor = UIColor.whiteColor()
    notifLabel.backgroundColor = UIColor(red:203/255, green:20/255,blue:82/255,alpha:1.0)
    notifLabel.textAlignment = NSTextAlignment.Center
    notifLabel.font = UIFont(name: "Avenir Book", size: 15)
    notifLabel.text = "\(notifNumber)"
    notifLabel.clipsToBounds = true;
    notifLabel.layer.cornerRadius = notifLabel.font.pointSize * 1.5 / 2
    notifLabel.alpha = 0;
    
    vc.view.addSubview(notifLabel)

}

func getNotif(){
    
    var myself = PFUser.currentUser()?.objectId
    
    var query = PFQuery(className: "Notifications")
    query.whereKey("authorId", equalTo: myself! )
    query.whereKey("sawNotif", equalTo: false)
    query.findObjectsInBackgroundWithBlock {
        (objects: [AnyObject]?, error: NSError?) -> Void in
        
        if error == nil {
            // The find succeeded.
            notifNumber = objects!.count
            
            if notifNumber != 0 {
                notifLabel.alpha = 1
            }
            
            if notifNumber != actualNotifNumber{
                if notifNumber != 0{
                    actualNotifNumber = notifNumber
                    notifLabel.text = "\(notifNumber)"
                }
                
            }
            
            
        } else {
            // Log details of the failure
            println("Error: \(error!) \(error!.userInfo!)")
        }
    }
    
    
}



class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true);
    }
    
}

