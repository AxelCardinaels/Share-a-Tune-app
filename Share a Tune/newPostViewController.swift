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

class NewPostViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate,  UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate{
    
    var manager:CLLocationManager!
    
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
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        photoPost.setBackgroundImage(image, forState: UIControlState.Normal)
        photoPost.titleLabel?.text = "Photo du morceau"
        pochetteMorceau.image = image;
        canSaveImage = true;
    }
    
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
    
    
    func getCurrentSong(){
        
        if var nowPlaying = MPMusicPlayerController.systemMusicPlayer().nowPlayingItem {
            
            var track = MPMusicPlayerController.systemMusicPlayer().nowPlayingItem
            trackName = nowPlaying.valueForProperty(MPMediaItemPropertyTitle) as! String
            
            trackArtist = nowPlaying.valueForProperty(MPMediaItemPropertyArtist) as! String
            trackAlbum = nowPlaying.valueForProperty(MPMediaItemPropertyAlbumTitle) as! String
            
            titreMorceau.text = trackName
            artisteMorceau.text = trackArtist
            
            var nameArray = trackName.componentsSeparatedByString(" ") as NSArray
            var artistArray = trackArtist.componentsSeparatedByString(" ") as NSArray
            var albumArray = trackAlbum.componentsSeparatedByString(" ") as NSArray
            
            
            trackNameURL = nameArray.componentsJoinedByString("+") as String
            trackArtistURL = artistArray.componentsJoinedByString("+") as String
            trackAlbumURL = albumArray.componentsJoinedByString("+")
            
            
            searchString = "https://itunes.apple.com/search?term=\(trackNameURL)+\(trackArtistURL)+\(trackAlbumURL)&entity=song"
            
            
            findSongInfo(searchString)
            
            
        } else {
            println("noSong")
        }
    }
    
    func launchMap(){
        manager = CLLocationManager();
        manager.delegate = self;
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func updateInfos(info : AnyObject){
        
        println(info["trackName"])
        
        
        var stringImage = info["artworkUrl100"] as! String
        var urlImage = stringImage.stringByReplacingOccurrencesOfString("100x100-75.jpg", withString: "600x600-75.jpg")
        var finalURL = NSURL(string: urlImage)
        
        let request: NSURLRequest = NSURLRequest(URL: finalURL!)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
            if error == nil {
                var image = UIImage(data: data)
                
                // Stocker l'image dans notre cache.
                
                self.pochetteMorceau.image = image
                self.photoPost.setBackgroundImage(image, forState: UIControlState.Normal)
                
            }
            else {
                println("Error: \(error.localizedDescription)")
            }
        })
        
        
        
        
        
    }
    
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
                    println("No infos found")
                }else{
                    self.songExist = true;
                    var resultats: AnyObject = jsonResult["results"]!
                    self.finalObject = resultats[0]
                    self.updateInfos(self.finalObject)
                }
                
            }
        })
        
        task.resume()
    }
    
    func makePostButton(){
        var postButton : UIBarButtonItem = UIBarButtonItem(title: "Publier", style: UIBarButtonItemStyle.Plain, target: self, action: "savePost")
        self.navigationItem.rightBarButtonItem = postButton
    }
    
    func textViewDidChange(textView: UITextView) { //Handle the text changes here
        var actualText : Int = count(textView.text) as Int
        var actualCount = 120 - actualText
        characterCount.text = "\(actualCount)"
    }
    
    
    func savePost(){
        
        var stringImage = finalObject["artworkUrl100"] as! String
        var urlImage = stringImage.stringByReplacingOccurrencesOfString("100x100-75.jpg", withString: "1400x1400-75.jpg")
        var imageNoCover = UIImage(named: "noCover")
        var imageData = UIImagePNGRepresentation(imageNoCover)
        var imageFile = PFFile(name:"noCover", data: imageData)
        
        if songExist == true{
            var post = PFObject(className:"Post")
            post["userName"] = PFUser.currentUser()?.username
            post["albumName"] = finalObject["collectionName"] as! String
            post["songName"] = titreMorceau.text
            post["artistName"] = artisteMorceau.text
            post["itunesLink"] = finalObject["trackViewUrl"] as! String
            post["previewLink"] = finalObject["previewUrl"] as! String
            post["postDescription"] = descriptionPost.text
            post["location"] = localisationText.text!.stringByReplacingOccurrencesOfString("Depuis ", withString: "")
            post["coverLink"] = urlImage as String
            post["postImage"] = imageFile
            
            post.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    println("Done")
                } else {
                    println("Shit happens")
                }
            }
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                    
                    var subThoroughfare:String = ""
                    
                    if p.subThoroughfare != nil{
                        subThoroughfare = p.subThoroughfare
                    }
                    self.localisationText.text = "Depuis \(p.subLocality)"
                }
            }
        })
        
        
    }
    
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
