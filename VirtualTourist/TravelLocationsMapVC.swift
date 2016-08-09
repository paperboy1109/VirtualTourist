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
    
    var sharedContext = CoreDataStack.sharedInstance().managedObjectContext
    
    var selectedPin: CustomPinAnnotation?
    
    var persistentDataService: PersistentDataService!
    
    var travelPins: [Pin] = []
    
    let latitudeKey = "Latitude Key"
    let longitudeKey = "Longitude Key"
    let latitudeDeltaKey = "Latitude Delta Key"
    let longitudeDeltaKey = "Longitude Delta Key"
    let previousUseKey = "App Prior Launch Key"
    
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
        setMapRegion()
        
        editAnnotationsView.hidden = true
        
        /* Configure the gesture recognizer */
        let touchAndHold = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationsMapVC.createNewAnnotation(_:)))
        touchAndHold.minimumPressDuration = 0.8
        mapView.addGestureRecognizer(touchAndHold)
        
        /* Get access to persisted data */
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
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let navigationBackButton = UIBarButtonItem()
        navigationBackButton.title = "Ok"
        navigationItem.backBarButtonItem = navigationBackButton
        
        if segue.identifier == "ToPhotoAlbum" {
            let photoAlbumVC = segue.destinationViewController as! PhotoAlbumVC
            photoAlbumVC.mapAnnotation = self.selectedPin
        }
    }
    
    // MARK: - Actions
    
    @IBAction func editTapped(sender: AnyObject) {
        
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
    
    func setMapRegion() {
        
        let startingLatitude = NSUserDefaults.standardUserDefaults().valueForKey(latitudeKey) as? Double
        let startingLongitude = NSUserDefaults.standardUserDefaults().valueForKey(longitudeKey) as? Double
        let coordinate = CLLocationCoordinate2DMake(startingLatitude!, startingLongitude!)
        
        let latDelta:CLLocationDegrees = NSUserDefaults.standardUserDefaults().valueForKey(latitudeDeltaKey) as! Double //0.01
        let lonDelta:CLLocationDegrees = NSUserDefaults.standardUserDefaults().valueForKey(longitudeDeltaKey) as! Double //0.01
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        
        let region:MKCoordinateRegion = MKCoordinateRegionMake(coordinate, span)
        
        self.mapView.setRegion(region, animated: true)
        
    }
    
    func createNewAnnotation(gestureRecognizer:UIGestureRecognizer) {
        
        // Only save a location once for a given long press
        if gestureRecognizer.state == UIGestureRecognizerState.Began && isInEditMode == false {
            
            /* Get the tapped location */
            
            let touchPoint = gestureRecognizer.locationInView(self.mapView)
            
            let newCoordinate = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            
            let location = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
            
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                
                var title = ""
                
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    print("There was an error when trying to geocode: \(error)")
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
                
                /* Create a Pin entity, a custom annotation based on it, and add an annotation to the map */
                print("Creating a new Pin entity .... ")
                let pinAnnotation = self.saveNewPinAndCreateAnnotation(annotation)
                self.mapView.addAnnotation(pinAnnotation)
                print("This annotation was added to the map: ")
                print(pinAnnotation.title)

            }
            
            
        }
        
    }
    
    func saveNewPinAndCreateAnnotation(mapAnnotation: MKPointAnnotation) -> CustomPinAnnotation {
        
        let touristLocation = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: self.sharedContext) as! Pin
        touristLocation.latitude = mapAnnotation.coordinate.latitude
        touristLocation.longitude = mapAnnotation.coordinate.longitude
        touristLocation.title = mapAnnotation.title
        CoreDataStack.sharedInstance().saveContext()
        
        let pinAnnotation = CustomPinAnnotation(pin: touristLocation, title: mapAnnotation.title, subtitle: nil)
        return pinAnnotation
        
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
        
        mapView.removeAnnotations(mapView.annotations)
        
        for item in travelPins {
            let pinAnnotation = CustomPinAnnotation(pin: item, title: item.title, subtitle: nil)
            self.mapView.addAnnotation(pinAnnotation)
        }
    }
    
    
}




extension TravelLocationsMapVC: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        // print("\nMap view region changed, saving new position\n")
        let currentRegion = mapView.region
        /*
         print("Here is currentRegion: \(currentRegion)")
         print("Here is currentRegion.center: \(currentRegion.center)")
         print("Here is currentRegion.span: \(currentRegion.span)") */
        
        NSUserDefaults.standardUserDefaults().setValue(Double(currentRegion.center.latitude), forKey: latitudeKey)
        NSUserDefaults.standardUserDefaults().setValue(Double(currentRegion.center.longitude), forKey: longitudeKey)
        NSUserDefaults.standardUserDefaults().setValue(Double(currentRegion.span.latitudeDelta), forKey: latitudeDeltaKey)
        NSUserDefaults.standardUserDefaults().setValue(Double(currentRegion.span.longitudeDelta), forKey: longitudeDeltaKey)
        
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {

        let customAnnotation = view.annotation as! CustomPinAnnotation
        
        /* This is the annotation that will be passed to the Photo Album */
        selectedPin = view.annotation as? CustomPinAnnotation
        
        if isInEditMode {
            
            /* Remove the annotation from the map */

            if let removablePin = selectedPin {
                mapView.removeAnnotation(removablePin)
            }
            selectedPin = nil
            
            /* Remove references to the pin and remove it from the data store */
            if let pinToRemove = customAnnotation.pin {
                
                /* Remove references to the Pin in travelPins; new Pin entities will not need this extra step */
                let indexOfPinToRemove = travelPins.indexOf(pinToRemove)
                
                if indexOfPinToRemove != nil {
                    travelPins.removeAtIndex(indexOfPinToRemove!)
                }
                persistentDataService.removePinEntity(pinToRemove)
                
                CoreDataStack.sharedInstance().saveContext()
            }
            
            
        } else {
            performSegueWithIdentifier("ToPhotoAlbum", sender: self)
        }
    }
}


