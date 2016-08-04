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
    
    var sharedContext = CoreDataStack.sharedInstance().managedObjectContext
    
    var mapAnnotation: CustomPinAnnotation!
    
    // MARK: - Outlets
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Configure the map */
        var mapRegion = MKCoordinateRegion()
        var mapSpan = MKCoordinateSpan()
        mapSpan.latitudeDelta = 0.02
        mapSpan.longitudeDelta = 0.02
        mapRegion.span = mapSpan
        mapRegion.center = mapAnnotation.coordinate
        
        mapView.zoomEnabled = false
        mapView.scrollEnabled = false
        mapView.pitchEnabled = false
        mapView.rotateEnabled = false
        mapView.userInteractionEnabled = false
        mapView.region = mapRegion
        
        mapView.addAnnotation(mapAnnotation)
        
        /* Configure the collection view */
        collectionView.delegate = self
        collectionView.dataSource = self
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        print("Here is the (custom) map annotation: ")
        print(self.mapAnnotation)
        print(self.mapAnnotation.title)
        print(self.mapAnnotation.pin)
    }
    
    // MARK: - Helpers
    
}


// MARK: - Delegate methods for the collection view

extension PhotoAlbumVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        // Filler code
        return 1
        
        // TODO: Implement the fetched results controller
        
        // Use the Fetched Results Controller
        //print("in numberOfSectionsInCollectionView()")
        //return self.fetchedResultsController.sections!.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Filler code
        return 1
        
        // TODO: Implement the fetched results controller
        // Use the Fetched Results Controller
        /*
        print("in collectionView(_:numberOfItemsInSection)")
        let sectionInfo = fetchedResultsController.sections![section]
        print("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects */
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        print("in collectionView(_:cellForItemAtIndexPath)")
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TouristPhotoCell", forIndexPath: indexPath) as UICollectionViewCell
        
        // let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! DeleteCellsCollectionViewCell
        // cell.imageView.backgroundColor = UIColor.blueColor()
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        print("in collectionView(_:didSelectItemAtIndexPath)")
        
        print("Cell at index path \(indexPath) was tapped ")

        
    }
    
}


