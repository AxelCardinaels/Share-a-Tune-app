//
//  UserSearchViewController.swift
//  Share a Tune
//
//  Created by Axel Cardinaels on 11/05/15.
//  Copyright (c) 2015 Axel Cardinaels. All rights reserved.
//

import UIKit

class UserSearchViewController: UIViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    
    var searchBar = UISearchBar()
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        //Mise en place de la barre de recherche dans la bar de navigation
        
        var colorTextSearchBar = searchBar.valueForKey("searchField") as? UITextField
        
        colorTextSearchBar?.textColor = UIColor.whiteColor()
        
        
        searchBar.sizeToFit()
        searchBar.searchBarStyle = UISearchBarStyle.Minimal
        //searchBar.setShowsCancelButton(true, animated: true)
        searchBar.placeholder = "Rechercher"
        self.navigationItem.titleView = searchBar
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
        // Dispose of any resources that can be recreated.
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
