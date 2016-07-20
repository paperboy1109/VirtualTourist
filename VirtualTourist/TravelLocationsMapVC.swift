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
    var coreDataStack = CoreDataStack()
    var managedObjectContext: NSManagedObjectContext!
    var request: NSFetchRequest!
    
    var focusAnnotation = MKPointAnnotation()
    
    var focusCoordinate = CLLocationCoordinate2D()
    
    var persistentDataService: PersistentDataService!
    
    var travelPins: [Pin] = []
    
    // MARK: - Outlets
    
    @IBOutlet var mapView: MKMapView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        /* Configure the gesture recognizer */
        let touchAndHold = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationsMapVC.createNewAnnotation(_:)))
        touchAndHold.minimumPressDuration = 0.8
        mapView.addGestureRecognizer(touchAndHold)
        
        /* Get access to persisted data */
        managedObjectContext = coreDataStack.managedObjectContext
        persistentDataService = PersistentDataService(managedObjectContext: managedObjectContext)        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
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
            photoAlbumVC.focusAnnotation = self.focusAnnotation
        }
        
        //TODO: Pass Pin details to the photo album when a pre-existing pin is tapped
    }
    
    // MARK: - Actions
    
    
    @IBAction func editTapped(sender: AnyObject) {
        print("edit tapped")
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
                
                self.mapView.addAnnotation(annotation)
                self.focusAnnotation = annotation
                
                /* Save the annotation using Core Data */
                /*
                 let touristLocation = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: self.coreDataStack.managedObjectContext) as! Pin
                 touristLocation.latitude = annotation.coordinate.latitude
                 touristLocation.longitude = annotation.coordinate.longitude
                 touristLocation.title = annotation.title
                 
                 self.coreDataStack.saveContext()
                 */
                
                self.savePin(annotation)
            }
            
            
        }
        
    }
    
    
    func savePin(mapAnnotation: MKPointAnnotation) {
        
        let touristLocation = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: self.coreDataStack.managedObjectContext) as! Pin
        touristLocation.latitude = mapAnnotation.coordinate.latitude
        touristLocation.longitude = mapAnnotation.coordinate.longitude
        touristLocation.title = mapAnnotation.title
        
        self.coreDataStack.saveContext()
        
    }
    
    func loadStoredPins() {
        
        /* Get stored travel locations and display them on the map */
        travelPins = persistentDataService.getPinEntities()
        
        for item in travelPins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: Double(item.latitude!), longitude: Double(item.longitude!))
            annotation.title = item.title!
            self.mapView.addAnnotation(annotation)
        }
    }
    
    
}




extension TravelLocationsMapVC: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("hello, you just selected an annotation view!")
        
        focusCoordinate = (view.annotation?.coordinate)!
        
        
        // segue: ToPhotoAlbum
        performSegueWithIdentifier("ToPhotoAlbum", sender: self)
    }
}


