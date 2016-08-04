//
//  PhotoAlbumVC.swift
//  VirtualTourist
//
//  Created by Daniel J Janiak on 7/19/16.
//  Copyright © 2016 Daniel J Janiak. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumVC: UIViewController {
    
    // MARK: - Properties
    
    var focusAnnotation = MKPointAnnotation()
    
    var focusCoordinate = CLLocationCoordinate2D()
    
    var mapAnnotation: CustomPinAnnotation!
    
    // MARK: - Outlets
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
         MKCoordinateRegion region;
         MKCoordinateSpan span;
         span.latitudeDelta = 0.01;
         span.longitudeDelta = 0.01;
         region.span = span;
         region.center = track; */
        
        var mapRegion = MKCoordinateRegion()
        var mapSpan = MKCoordinateSpan()
        mapSpan.latitudeDelta = 0.02
        mapSpan.longitudeDelta = 0.02
        mapRegion.span = mapSpan
        //mapRegion.center = CLLocationCoordinate2D(latitude: focusAnnotation.coordinate.latitude, longitude: focusAnnotation.coordinate.longitude)
        mapRegion.center = focusCoordinate
        
        mapView.zoomEnabled = false
        mapView.scrollEnabled = false
        mapView.pitchEnabled = false
        mapView.rotateEnabled = false
        mapView.userInteractionEnabled = false
        mapView.region = mapRegion
        
        if focusAnnotation.coordinate.latitude != 0.0 && focusAnnotation.coordinate.longitude != 0 {
            mapView.addAnnotation(focusAnnotation)
        } else {
            let annotation = MKPointAnnotation()
            annotation.coordinate = focusCoordinate
            mapView.addAnnotation(annotation)
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        print("(PhotoAlbum, viewWillLoad)")
        print(focusAnnotation.coordinate.latitude)
        print(focusAnnotation.coordinate.longitude)
        
        print("Here is the map annotation: ")
        print(self.mapAnnotation)
        print(self.mapAnnotation.title)
        print(self.mapAnnotation.pin)
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
