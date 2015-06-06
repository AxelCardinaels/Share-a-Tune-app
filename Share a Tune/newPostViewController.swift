//
//  NewPostViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 20/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit
import MapKit
import Parse
import Foundation
import SystemConfiguration
import MediaPlayer
import Social

class NewPostViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate,  UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate{
    
    //-------------- Variables générales pour le controller actuel  -----------------//
    
    
    
    @IBOutlet var deletePictureBouton: UIButton!
    @IBOutlet var facebookButton: UIButton!
    @IBOutlet var localisationText: UILabel!
    @IBOutlet var descriptionPost: UITextView!
    @IBOutlet var photoPost: UIButton!
    @IBOutlet var localisationMap: MKMapView!
    @IBOutlet var titreMorceau: UILabel!
    @IBOutlet var artisteMorceau: UILabel!
    @IBOutlet var pochetteMorceau: UIImageView!
    @IBOutlet var characterCount: UILabel!
    var trackName = ""
    var trackNameURL = ""
    var trackArtist = ""
    var trackArtistURL = ""
    var trackAlbum = ""
    var trackAlbumURL = ""
    var searchString = ""
    var finalObject : AnyObject = ""
    var canSaveImage = false
    var songExist = false
    var canPost = ""
    var actualCount = Int()
    var gotLocation = false
    var noCoverImage : UIImage = UIImage(named: "noCover")!
    var hasCoverImage : UIImage = UIImage(named: "noCover")!
    var hasCustomImage : UIImage = UIImage(named: "noCover")!
    var doHaveCover = false
    var doHaveCustom = false
    var actualImageType = ""
    var hasAlbum = true
    var hasArtist = true;
    
    //-------------- Variables pour l'affichage des erreurs -----------------//
    
    @IBOutlet var erreurBar: UILabel!
    var error = ""
    
    func timeOut(){
        time = true;
        errorFade(time, self.erreurBar)
    }
    
    
    //-------------- Gestion de la carte -----------------//
    
    var manager:CLLocationManager!
    
    func launchMap(){
        
        localisationText.text = "Localisation désactivée"
        manager = CLLocationManager();
        manager.delegate = self;
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        var userLocation:CLLocation = locations[0] as! CLLocation
        
        var latitude = userLocation.coordinate.latitude
        var longitude = userLocation.coordinate.longitude
        
        
        var latDelta:CLLocationDegrees = 0.001 //Zoom
        var lonDelta:CLLocationDegrees = 0.001
        
        
        var span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        
        var location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        
        var region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        
        self.localisationMap.setRegion(region, animated: true)
        
        CLGeocoder().reverseGeocodeLocation(userLocation, completionHandler: { (placemarks, error) -> Void in
            if error != nil{
                println(error);
            }else{
                if let p = CLPlacemark(placemark: placemarks?[0] as! CLPlacemark){
                    
                    self.gotLocation = true;
                    
                    var subThoroughfare:String = ""
                    
                    if p.subThoroughfare != nil{
                        subThoroughfare = p.subThoroughfare
                    }
                    
                    if p.subLocality == nil{
                        self.localisationText.text = "Depuis \(p.locality)"
                    }else{
                        self.localisationText.text = "Depuis \(p.subLocality)"
                    }
                    
                }
            }
        })
        
        
    }
    
    
    //-------------- Gestion de l'upload de photo -----------------//
    
    
    //Choix du mode d'importation via le système d'alert
    
    @IBAction func ChoixPhoto(sender: AnyObject) {
        var alert = UIAlertController(title: nil, message: "Choisissez la source de votre photo", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        
        if isCamera == true{
            alert.addAction(UIAlertAction(title: "Prendre une photo", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                var image = UIImagePickerController()
                image.delegate = self
                image.sourceType = UIImagePickerControllerSourceType.Camera
                image.allowsEditing = true;
                
                self.presentViewController(image, animated: true, completion: nil)
            }))
        }
        
        
        
        alert.addAction(UIAlertAction(title: "Choisir une photo enregistrée", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            var image = UIImagePickerController()
            image.delegate = self
            image.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            image.allowsEditing = true;
            
            self.presentViewController(image, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Annuler", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    
    //Une fois la photo choisie, on l'utilise la ou l'on veut.
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        photoPost.setImage(image, forState: UIControlState.Normal)
        photoPost.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        photoPost.titleLabel?.text = "Photo du morceau"
        pochetteMorceau.image = image;
        hasCustomImage = image
        canSaveImage = true;
        doHaveCustom = true;
        actualImageType = "custom"
        showDeletePictureButton()
    }
    
    
    func showDeletePictureButton(){
        deletePictureBouton.alpha = 1
    }
    
    func hideDeletePictureButton(){
        deletePictureBouton.alpha = 0
    }
    
    @IBAction func deletePicture(sender: AnyObject) {
        
        if actualImageType == "cover"{
            photoPost.setImage(noCoverImage, forState: UIControlState.Normal)
            photoPost.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            pochetteMorceau.image = noCoverImage
            canSaveImage = true
            doHaveCover = false
            actualImageType = ""
            
            hideDeletePictureButton()
        }
        
        
        if actualImageType == "custom"{
            if doHaveCover == true{
                
                photoPost.setImage(hasCoverImage, forState: UIControlState.Normal)
                pochetteMorceau.image = hasCoverImage
                canSaveImage = false
                actualImageType = "cover"
                doHaveCustom = false
            }else{
                
                photoPost.setImage(noCoverImage, forState: UIControlState.Normal)
                photoPost.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                pochetteMorceau.image = noCoverImage
                canSaveImage = false
                actualImageType = ""
                hideDeletePictureButton()
            }
        }
        
        
        
        
    }
    
    
    
    
    
    //-------------- Récupération de la chanson actuelle -----------------//
    
    
    func getCurrentSong(){
        
        if var nowPlaying = MPMusicPlayerController.systemMusicPlayer().nowPlayingItem {
            
            var track = MPMusicPlayerController.systemMusicPlayer().nowPlayingItem
            
            
            if nowPlaying.valueForProperty(MPMediaItemPropertyTitle) == nil{
               trackName = "Morceau inconnu"
                self.error = "noSong"
                showError(self, self.error, self.erreurBar)
                var timer = NSTimer()
                timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
                titreMorceau.text = "Pas de morceau"
                artisteMorceau.text = "Pas d'artiste"
                descriptionPost.text = "Il faut au moins le titre pour trouver !"
                canPost = "noSong"
                

            }else{
                
                trackName = nowPlaying.valueForProperty(MPMediaItemPropertyTitle) as! String
                if nowPlaying.valueForProperty(MPMediaItemPropertyArtist) == nil {
                    trackArtist = "Artiste Inconnu"
                    hasArtist = false;
                    
                }else{
                    trackArtist = nowPlaying.valueForProperty(MPMediaItemPropertyArtist) as! String
                }
                
                if nowPlaying.valueForProperty(MPMediaItemPropertyAlbumTitle) == nil {
                    trackAlbum = "Album Inconnu"
                    hasAlbum = false;
                }else{
                    trackAlbum = nowPlaying.valueForProperty(MPMediaItemPropertyAlbumTitle) as! String
                }
                
                
                
                titreMorceau.text = trackName
                titreMorceau.accessibilityLabel = "Chanson : \(trackName)"
                artisteMorceau.text = trackArtist
                artisteMorceau.accessibilityLabel = "Artiste : \(artisteMorceau)"
                
                
                var nameArray = trackName.componentsSeparatedByString(" ") as NSArray
                var artistArray = trackArtist.componentsSeparatedByString(" ") as NSArray
                var albumArray = trackAlbum.componentsSeparatedByString(" ") as NSArray
                
                
                trackNameURL = nameArray.componentsJoinedByString("+") as String
                trackArtistURL = artistArray.componentsJoinedByString("+") as String
                trackAlbumURL = albumArray.componentsJoinedByString("+")
                
                if hasArtist == true && hasAlbum == true {
                  searchString = "https://itunes.apple.com/search?term=\(trackNameURL)+\(trackArtistURL)+\(trackAlbumURL)&entity=song"
                }
                
                if hasArtist == false && hasAlbum == true {
                    searchString = "https://itunes.apple.com/search?term=\(trackNameURL)+\(trackAlbumURL)&entity=song"
                }
                
                if hasArtist == true && hasAlbum == false {
                    searchString = "https://itunes.apple.com/search?term=\(trackNameURL)+\(trackArtistURL)&entity=song"
                }
                
                if hasArtist == false && hasAlbum == false {
                    searchString = "https://itunes.apple.com/search?term=\(trackNameURL)&entity=song"
                }
                
                
                println(searchString)
                
                
                findSongInfo(searchString)

            }
            
            
            
            
        } else {
            self.error = "noSong"
            showError(self, self.error, self.erreurBar)
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
            titreMorceau.text = "Pas de morceau"
            artisteMorceau.text = "Pas d'artiste"
            descriptionPost.text = "Vous pourriez réessayer en écoutant de la musique s'il vous plait ? Merci !"
            canPost = "noSong"
            
            
        }
    }
    
    //-------------- Trouver les infos pour la chanson actuelle -----------------//
    
    func findSongInfo(searchURL : String){
        
        let urlPath = searchString.stringByFoldingWithOptions(NSStringCompareOptions.DiacriticInsensitiveSearch, locale: NSLocale.currentLocale())
        let url = NSURL(string: urlPath)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            if error != nil {
                println(error)
            }else{
                let jsonResult =  NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                var resultCount: AnyObject = jsonResult["resultCount"]!
                
                if resultCount as! NSObject == 0{
                    self.songExist = false;
                    
                }else{
                    self.songExist = true;
                    var resultats: AnyObject = jsonResult["results"]!
                    self.finalObject = resultats[0]
                    self.updateInfos(self.finalObject)
                    self.makeFacebookButton()
                }
                self.makeFacebookButton()
                
                
            }
            
        })
        
        task.resume()
        
    }
    
    //-------------- Mise à jour des informations pour le titre trouvé par l'API  -----------------//
    
    func updateInfos(info : AnyObject){
        
        var stringImage = info["artworkUrl100"] as! String
        var urlImage = stringImage.stringByReplacingOccurrencesOfString("100x100-75.jpg", withString: "600x600-75.jpg")
        var finalURL = NSURL(string: urlImage)
        
        let request: NSURLRequest = NSURLRequest(URL: finalURL!)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
            if error == nil {
                var image = UIImage(data: data)
                
                // Stocker l'image dans notre cache.
                
                self.pochetteMorceau.image = image
                self.photoPost.setImage(image, forState: UIControlState.Normal)
                self.photoPost.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                self.descriptionPost.text = "Dites quelque chose de sympa à propos de votre coup de coeur..."
                self.hasCoverImage = UIImage(data: data)!
                self.doHaveCover = true
                self.showDeletePictureButton()
                self.actualImageType = "cover"
                
                
            }
            else {
                println("Error: \(error.localizedDescription)")
            }
        })
        
    }
    
    //-------------- Envoie du post sur le serveur  -----------------//
    
    
    
    func savePost(){
        
        if error == ""{
            
            if canPost == ""{
                
                if songExist == true{
                    
                    var stringImage = finalObject["artworkUrl100"] as! String
                    var urlImage = stringImage.stringByReplacingOccurrencesOfString("100x100-75.jpg", withString: "1400x1400-75.jpg")
                    var imageNoCover = UIImage(named: "noCover")
                    var imageData = UIImagePNGRepresentation(imageNoCover)
                    var imageFile = PFFile(name:"noCover", data: imageData)
                    
                    if actualCount >= 0 {
                        
                        var spinner = activityIndicatorHeaderMake()
                        var ButtonSpinner : UIBarButtonItem = UIBarButtonItem(customView: spinner)
                        self.navigationItem.rightBarButtonItem = nil
                        self.navigationItem.rightBarButtonItem = ButtonSpinner
                        
                        var post = PFObject(className:"Post")
                        
                        post["userID"] = PFUser.currentUser()?.objectId!
                        post["albumName"] = finalObject["collectionName"] as! String
                        post["songName"] = titreMorceau.text
                        post["artistName"] = artisteMorceau.text
                        post["itunesLink"] = finalObject["trackViewUrl"] as! String
                        post["previewLink"] = finalObject["previewUrl"] as! String
                        post["postDescription"] = descriptionPost.text
                        
                        if gotLocation == false {
                            post["location"] = "noLocalisation"
                        }else{
                            post["location"] = localisationText.text!.stringByReplacingOccurrencesOfString("Depuis ", withString: "")
                        }
                        
                        
                        if canSaveImage == true{
                            
                            var imageData = UIImagePNGRepresentation(pochetteMorceau.image)
                            var imageFile = PFFile(name:"customCover", data: imageData)
                            
                            post["coverLink"] = "customImage"
                            post["postImage"] = imageFile
                            
                            
                        }else{
                            post["coverLink"] = urlImage as String
                            post["postImage"] = imageFile
                        }
                        
                        
                        post.saveInBackgroundWithBlock {
                            (success: Bool, error: NSError?) -> Void in
                            if (success) {
                                activityIndicatorButton.stopAnimating()
                                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                                self.navigationItem.rightBarButtonItem = nil
                                self.makePostButton()
                                
                                
                                self.performSegueWithIdentifier("GoToFeed", sender: self)
                            } else {
                                println("Shit happens")
                            }
                        }
                    }else{
                        
                        self.error = "descriptionTooLong"
                    }
                    
                    
                }else{
                    if actualCount >= 0 {
                        
                        
                        var spinner = activityIndicatorHeaderMake()
                        var ButtonSpinner : UIBarButtonItem = UIBarButtonItem(customView: spinner)
                        self.navigationItem.rightBarButtonItem = nil
                        self.navigationItem.rightBarButtonItem = ButtonSpinner
                        
                        var post = PFObject(className:"Post")
                        
                        post["userID"] = PFUser.currentUser()?.objectId
                        post["albumName"] = trackAlbum
                        post["songName"] = titreMorceau.text
                        post["artistName"] = artisteMorceau.text
                        post["itunesLink"] = "noLink"
                        post["previewLink"] = "noPreview"
                        post["postDescription"] = descriptionPost.text
                        
                        if gotLocation == false {
                            post["location"] = "noLocalisation"
                        }else{
                            post["location"] = localisationText.text!.stringByReplacingOccurrencesOfString("Depuis ", withString: "")
                        }
                        
                        if canSaveImage == true{
                            
                            var imageData = UIImagePNGRepresentation(pochetteMorceau.image)
                            var imageFile = PFFile(name:"customCover", data: imageData)
                            
                            post["coverLink"] = "customImage"
                            post["postImage"] = imageFile
                            
                            
                        }else{
                            var imageBase = UIImage(named: "noCover")
                            var imageData = UIImagePNGRepresentation(imageBase)
                            var imageFile = PFFile(name:"noCover", data: imageData)
                            
                            post["coverLink"] = "noCover"
                            post["postImage"] = imageFile
                        }
                        
                        
                        post.saveInBackgroundWithBlock {
                            (success: Bool, error: NSError?) -> Void in
                            if (success) {
                                activityIndicatorButton.stopAnimating()
                                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                                self.navigationItem.rightBarButtonItem = nil
                                self.makePostButton()
                                self.performSegueWithIdentifier("GoToFeed", sender: self)
                            }else {
                                println("Shit happens")
                            }
                        }
                    }else{
                        
                        self.error = "descriptionTooLong"
                    }
                }
            }
            
        }
        
        if error != "" {
            showError(self, self.error, self.erreurBar)
            var timer = NSTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: Selector("timeOut"), userInfo: nil, repeats: false)
        }
        
    }
    
    
    
    
    //-------------- Gestion du UITexView ( Placeholder + limite de caractères)  -----------------//
    
    
    //Si la valeur du texte équivaut au placeholder, on vide le textfield
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == "Dites quelque chose de sympa à propos de votre coup de coeur..." || textView.text == "Impossible de trouver des informations pour ce titre... Mais n'hésitez pas à le partager quand même !" {
            textView.text = nil
        }
    }
    
    //Comptage du nombre de caractères
    
    func textViewDidChange(textView: UITextView) { //Handle the text changes here
        var actualText : Int = count(textView.text) as Int
        actualCount = 120 - actualText
        characterCount.text = "\(actualCount)"
        characterCount.accessibilityLabel = "\(actualCount) caractères restants"
    }
    
    //Check pour remettre le placeholder en place ou pas
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text.isEmpty {
            
            if songExist == false{
                textView.text = "Impossible de trouver des informations pour ce titre... Mais n'hésitez pas à le partager quand même !"
            }else{
                textView.text = "Dites quelque chose de sympa à propos de votre coup de coeur..."
            }
        }
    }
    
    
    //-------------- Création des boutons utilitaires -----------------//
    
    func makePostButton(){
        var postButton : UIBarButtonItem = UIBarButtonItem(title: "Publier", style: UIBarButtonItemStyle.Plain, target: self, action: "savePost")
        self.navigationItem.rightBarButtonItem = postButton
    }
    
    func makeFacebookButton(){
        let content : FBSDKShareLinkContent = FBSDKShareLinkContent()
        
        
        if songExist{
            var url: AnyObject! = finalObject["trackViewUrl"]!
            content.contentURL = NSURL(string: url as! String)
        }else{
            content.contentURL = NSURL(string: "http://www.axelcardinaels.be/shareatuneapp")
            content.imageURL = NSURL(string: "http://www.axelcardinaels.be/shareatuneapp/img/nocover.jpg")
        }
        
        content.contentTitle = "Nouveau Coup de Coeur !"
        content.contentDescription = "Je viens de partager un nouveau Coup de Coeur sur l'application Share a Tune, \(trackName) par \(trackArtist) !"
        
        
        let button : FBSDKShareButton = FBSDKShareButton()
        button.shareContent = content
        
        button.frame = CGRectMake(facebookButton.frame.origin.x, facebookButton.frame.origin.y, facebookButton.frame.width, facebookButton.frame.height)
        self.view.addSubview(button)
        button.alpha = 0.05;
    }
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        killPlayer()
        
        getCurrentSong()
        launchMap()
        makePostButton()
        
        self.pochetteMorceau.layer.borderWidth = 3.0;
        self.pochetteMorceau.layer.borderColor = UIColor.whiteColor().CGColor
        descriptionPost.delegate = self
        
        // Do any additional setup after loading the view.
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true);
    }
    
    
    
    
}
