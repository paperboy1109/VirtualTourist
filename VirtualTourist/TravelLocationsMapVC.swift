//
//  TravelLocationsMapVC.swift
//  VirtualTourist
//
//  Created by Daniel J Janiak on 7/19/16.
//  Copyright © 2016 Daniel J Janiak. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapVC: UIViewController {
    
    // MARK: - Properties
    
    // var coreDataStack = CoreDataStack()
    // var managedObjectContext: NSManagedObjectContext!
    var sharedContext = CoreDataStack.sharedInstance().managedObjectContext
    
    var request: NSFetchRequest!
    
    var focusAnnotation = MKPointAnnotation()
    
    var focusCoordinate = CLLocationCoordinate2D()
    
    var selectedPin: CustomPinAnnotation!
    
    var persistentDataService: PersistentDataService!
    
    var travelPins: [Pin] = []
    
    var initialVerticalPosForMap: CGFloat!
    
    var isInEditMode: Bool = false
    
    let fontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
    
    // MARK: - Outlets
    
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var editButton: UIBarButtonItem!
    
    @IBOutlet var editAnnotationsView: UIView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        editAnnotationsView.hidden = true
        
        /* Configure the gesture recognizer */
        let touchAndHold = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationsMapVC.createNewAnnotation(_:)))
        touchAndHold.minimumPressDuration = 0.8
        mapView.addGestureRecognizer(touchAndHold)
        
        /* Get access to persisted data */
        // managedObjectContext = coreDataStack.managedObjectContext
        // persistentDataService = PersistentDataService(managedObjectContext: managedObjectContext)
        persistentDataService = PersistentDataService(managedObjectContext: sharedContext)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initialVerticalPosForMap = mapView.frame.origin.y
        
        if !isInEditMode {
            editButton.title = "Edit"
        } else {
            editButton.title = "Done"
            if let font = UIFont(name: "Helvetica Neue", size: 15) {
                print("Trying to apply font ... ")
                editButton.setTitleTextAttributes([NSFontAttributeName: font], forState: UIControlState.Normal)
            }
        }
        
        loadStoredPins()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        
        let navigationBackButton = UIBarButtonItem()
        navigationBackButton.title = "Ok"
        navigationItem.backBarButtonItem = navigationBackButton
        
        if segue.identifier == "ToPhotoAlbum" {
            let photoAlbumVC = segue.destinationViewController as! PhotoAlbumVC         
            photoAlbumVC.mapAnnotation = self.selectedPin
        }
        
        //TODO: Pass Pin details to the photo album when a pre-existing pin is tapped
    }
    
    // MARK: - Actions
    
    
    @IBAction func editTapped(sender: AnyObject) {
        //deleteAllPins()
        print("edit tapped")
        
        if !isInEditMode {
            if mapView.frame.origin.y >= initialVerticalPosForMap {
                mapView.frame.origin.y -= editAnnotationsView.frame.height
            }
            
            editButton.title = "Done"
            editAnnotationsView.hidden = false
            isInEditMode = true
            
        } else {
            
            editAnnotationsView.hidden = true
            mapView.frame.origin.y = initialVerticalPosForMap
            editButton.title = "Edit"
            isInEditMode = false
        }
    }
    
    
    // MARK: - Helpers
    
    func createNewAnnotation(gestureRecognizer:UIGestureRecognizer) {
        
        // Only save a location once for a given long press
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            
            /* Get the tapped location */
            
            let touchPoint = gestureRecognizer.locationInView(self.mapView)
            
            let newCoordinate = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            
            let location = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
            
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                
                var title = ""
                
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    print("There was an error with your request: \(error)")
                    return
                }
                
                /* GUARD: Was location data returned? */
                guard let placemarks = placemarks else {
                    print("No location data was returned")
                    return
                }
                
                /* Describe the tapped location */
                let newTravelLocation = placemarks[0]
                
                var subThoroughfare: String = ""
                var thoroughfare: String = ""
                var comma: String = ""
                var city: String = ""
                
                if newTravelLocation.locality != nil {
                    city = newTravelLocation.locality!
                }
                
                if newTravelLocation.thoroughfare != nil {
                    thoroughfare = newTravelLocation.thoroughfare!
                    comma = ","
                }
                
                if newTravelLocation.subThoroughfare != nil {
                    subThoroughfare = newTravelLocation.subThoroughfare!
                }
                
                title = "\(subThoroughfare) \(thoroughfare)\(comma) \(city)"
                
                if title == "" {
                    title = "Added \(NSDate())"
                }
                
                /* Create the new annotation */
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = newCoordinate
                annotation.title = title
                
                self.focusAnnotation = annotation
                
                // *** Use custom class ***
                //self.mapView.addAnnotation(annotation)
                //let newPin = Pin(entity: <#T##NSEntityDescription#>, insertIntoManagedObjectContext: <#T##NSManagedObjectContext?#>)
                //let pinAnnotation = CustomPinAnnotation(pin: item, title: item.title, subtitle: nil)
                //self.mapView.addAnnotation(pinAnnotation)
                
                /* Create a Pin entity, a custom annotation based on it, and add an annotation to the map */
                print("Creating a new Pin entity .... ")
                let pinAnnotation = self.saveNewPinAndCreateAnnotation(annotation)
                self.mapView.addAnnotation(pinAnnotation)
                print("This annotation was added to the map: ")
                print(pinAnnotation.title)
                
                
                
                
                /* Save the annotation using Core Data */
                /*
                 let touristLocation = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: self.coreDataStack.managedObjectContext) as! Pin
                 touristLocation.latitude = annotation.coordinate.latitude
                 touristLocation.longitude = annotation.coordinate.longitude
                 touristLocation.title = annotation.title
                 
                 self.coreDataStack.saveContext()
                 */
                
                
                
                // self.savePin(annotation)
            }
            
            
        }
        
    }
    
    
    func savePin(mapAnnotation: MKPointAnnotation) {
        
        // let touristLocation = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: self.coreDataStack.managedObjectContext) as! Pin
        let touristLocation = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: self.sharedContext) as! Pin
        touristLocation.latitude = mapAnnotation.coordinate.latitude
        touristLocation.longitude = mapAnnotation.coordinate.longitude
        touristLocation.title = mapAnnotation.title
        
        //self.coreDataStack.saveContext()
        CoreDataStack.sharedInstance().saveContext()
        
    }
    
    func saveNewPinAndCreateAnnotation(mapAnnotation: MKPointAnnotation) -> CustomPinAnnotation {
        
        // let touristLocation = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: self.coreDataStack.managedObjectContext) as! Pin
        let touristLocation = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: self.sharedContext) as! Pin
        touristLocation.latitude = mapAnnotation.coordinate.latitude
        touristLocation.longitude = mapAnnotation.coordinate.longitude
        touristLocation.title = mapAnnotation.title
        CoreDataStack.sharedInstance().saveContext()
        
        let pinAnnotation = CustomPinAnnotation(pin: touristLocation, title: mapAnnotation.title, subtitle: nil)
        return pinAnnotation
        
    }
    
    func deletePin(mapAnnotation: MKPointAnnotation) {
        
        // let touristLocation = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: self.coreDataStack.managedObjectContext) as! Pin
        let touristLocation = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: self.sharedContext) as! Pin
        touristLocation.latitude = mapAnnotation.coordinate.latitude
        touristLocation.longitude = mapAnnotation.coordinate.longitude
        touristLocation.title = mapAnnotation.title
        
        // self.coreDataStack.saveContext()
        CoreDataStack.sharedInstance().saveContext()
    }
    
    func deleteAllPins() {
        travelPins = persistentDataService.getPinEntities()
        for item in travelPins {
            self.sharedContext.deleteObject(item)
        }
        CoreDataStack.sharedInstance().saveContext()
    }
    
    func loadStoredPins() {
        
        /* Get stored travel locations and display them on the map */
        travelPins = persistentDataService.getPinEntities()
        
        /*
        for item in travelPins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: Double(item.latitude!), longitude: Double(item.longitude!))
            annotation.title = item.title!
            self.mapView.addAnnotation(annotation)
        } */
        
        for item in travelPins {
            let pinAnnotation = CustomPinAnnotation(pin: item, title: item.title, subtitle: nil)
            self.mapView.addAnnotation(pinAnnotation)
        }
    }
    
    
}




extension TravelLocationsMapVC: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        print("\nhello, you just selected an annotation view!")
        
        for item in travelPins {
            print(item.latitude as! Double)
            print((view.annotation?.coordinate.latitude)! as Double)
        }
        
        focusCoordinate = (view.annotation?.coordinate)!
        print("The focusCoordinate is: ")
        print(focusCoordinate)
        
        print("The associated Pin entity is: ")
        let customAnnotation = view.annotation as! CustomPinAnnotation
        print(customAnnotation)
        print(customAnnotation.pin)
        print(travelPins.indexOf(customAnnotation.pin))
        
        /* This is the annotation that will be passed to the Photo Album */
        selectedPin = view.annotation as! CustomPinAnnotation
        
        if isInEditMode {
            
            let pinToRemove = customAnnotation.pin
            travelPins.removeAtIndex(travelPins.indexOf(pinToRemove)!)
            persistentDataService.removePinEntity(pinToRemove)
            
            /* Remove the Pin entity associated with the annotation */
            // persistentDataService.removePinEntity(travelPins[travelPins.indexOf(customAnnotation.pin)!])
            // travelPins.removeAtIndex(travelPins.indexOf(customAnnotation.pin)!)
            
            
            // Causes crash ---
            //travelPins.removeAtIndex(travelPins.indexOf(customAnnotation.pin)!)
            //persistentDataService.removePinEntity(customAnnotation.pin)
            // -------------------------------------------------------------
            
            CoreDataStack.sharedInstance().saveContext()
            
            /* Remove the annotation from the map */
            mapView.removeAnnotation(view.annotation!)
            
            
            /*
            print("Checking for equality ... ")
            for item in travelPins {
                print("looping ...")
                
                if item.latitude == focusCoordinate.latitude && item.longitude == focusCoordinate.longitude {
                    print("It's a match!")
                    
                    print(travelPins[travelPins.indexOf(item)!])
                    
                    persistentDataService.removePinEntity(travelPins[travelPins.indexOf(item)!])
                    
                    travelPins.removeAtIndex(travelPins.indexOf(item)!)
                    
                    // self.coreDataStack.saveContext()
                    CoreDataStack.sharedInstance().saveContext()
                    
                    /* Remove the annotation from the map */
                    mapView.removeAnnotation(view.annotation!)
                    
                }
 
                
                /*
                if (item.latitude as! Double) == ((view.annotation?.coordinate.latitude)! as Double) {
                    print("hello")
                    
                    print(travelPins.indexOf(item))
                    
                    travelPins.removeAtIndex(travelPins.indexOf(item)!)
                    self.coreDataStack.saveContext()
                } */
            }
            */

            
        } else {                        
            // segue: ToPhotoAlbum
            performSegueWithIdentifier("ToPhotoAlbum", sender: self)
        }
    }
}


