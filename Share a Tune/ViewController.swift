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

var errors = ["invalidEmail" : "Merci d'entrer une adresse email valide", "takenEmail" : "Cette adresse email est déja utilisée", "takenUser" : "Ce nom d'utilisateur est déja utilisé", "empty" : "Merci de remplir tous les champs", "noInternet" : "Vous n'êtes pas connecté à internet", "noSpec" : "Merci de pas utiliser caractères spéciaux", "noSpecUser" : "Caractères spéciaux autorisés : '- _ et .'", "shortPassword" : "Le mot de passe doit dépasser 6 caractères", "shortUsername" : "Le nom d'utilisateur doit dépasser 2 caractères", "badLogin" : "Nom d'utilisateur ou Mot de passe incorrects", "noVerif" : "Merci de valider votre compte avant de vous connecter"]

var isCamera = UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice(rawValue: 0)!)

//Fonction pour checker si internet est présent

func isConnectedToNetwork() -> Bool {
    
    var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
    zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
        SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
    }
    
    var flags: SCNetworkReachabilityFlags = 0
    if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
        return false
    }
    
    let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
    let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    
    return (isReachable && !needsConnection) ? true : false
}

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
        
    default:
        bar.text = "Oups, Erreur inconnue"
    }
    
    
    
    UIView.animateWithDuration(0.8, animations: { () -> Void in
        bar.alpha = 1.0
    })
    
    
}

var time:Bool = false;

func errorFade(time : Bool, bar : UILabel){
    println(time)
    if time == true{
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            var daBar: UILabel = bar
            daBar.alpha = 0
            
        })
    }
    
}

//Gestion du loader

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

func activityIndicatorButtonKill(button:UIButton){
    button.setTitle(activityButtonText, forState: UIControlState.Normal)
    activityIndicatorButton.stopAnimating()
    UIApplication.sharedApplication().endIgnoringInteractionEvents()
    
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

