//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Daniel J Janiak on 7/19/16.
//  Copyright © 2016 Daniel J Janiak. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    /* Persist the map view location */
    func configureMap() {
        
        let latitudeKey = "Latitude Key"
        let longitudeKey = "Longitude Key"
        
        let latitudeDeltaKey = "Latitude Delta Key"
        let longitudeDeltaKey = "Longitude Delta Key"
        
        let previousUseKey = "App Prior Launch Key"
       
        let previousLatitude: Double
        let previousLongitude: Double
        let previouslatitudeDelta: Float
        let previouslongitudeDelta: Float
        
        if NSUserDefaults.standardUserDefaults().boolForKey(previousUseKey) {
            
            //print("The app has been used before")
            
        } else {
            
            //print("The app has not been used before")
            
            /* This is the default view of North America */
            //            defaultCenter = CLLocationCoordinate2D(latitude: 37.13283999999998, longitude: -95.785579999999996)
            //            defaultSpan = MKCoordinateSpan(latitudeDelta: 72.355996899647238, longitudeDelta: 61.276016959789544)
            
            previousLatitude = 37.13283999999998
            previousLongitude = -95.785579999999996
            previouslatitudeDelta = 72.355996899647238
            previouslongitudeDelta = 61.276016959789544
            
            /* The app will no longer be launching for the first time */
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: previousUseKey)
            
            NSUserDefaults.standardUserDefaults().setValue(previousLatitude, forKey: latitudeKey)
            NSUserDefaults.standardUserDefaults().setValue(previousLongitude, forKey: longitudeKey)
            
            NSUserDefaults.standardUserDefaults().setValue(previouslatitudeDelta, forKey: latitudeDeltaKey)
            NSUserDefaults.standardUserDefaults().setValue(previouslongitudeDelta, forKey: longitudeDeltaKey)
            
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
    }

    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        /* Set the managed object context */
        //let coreDataStack = CoreDataStack()
        
        //let rootNavigationController = self.window?.rootViewController as! UINavigationController
        //let initialVC = rootNavigationController.topViewController as! TravelLocationsMapVC
        //initialVC.managedObjectContext = coreDataStack.managedObjectContext
        
        checkDataStore()
        
        configureMap()
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    // MARK: - Helpers
    
    func checkDataStore() {
        
        print("Checking the data store ... ")
        
        let coreDataStack = CoreDataStack()
        let request = NSFetchRequest(entityName: "Pin")
        
        let pinCount = coreDataStack.managedObjectContext.countForFetchRequest(request, error: nil)
        print("There are \(pinCount) total pins in the data store. \n\n\n\n")
    }
    
    
}

