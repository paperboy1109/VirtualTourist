//
//  CustomPinAnnotation.swift
//  VirtualTourist
//
//  Created by Daniel J Janiak on 8/3/16.
//  Copyright © 2016 Daniel J Janiak. All rights reserved.
//

import MapKit

class CustomPinAnnotation: NSObject, MKAnnotation {
    
    var pin: Pin
    
    // Conform to the MKAnnotation protocol
    var title: String?
    var subtitle: String?
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D( latitude: pin.latitude as! Double, longitude: pin.longitude as! Double)
    }
    
    init(pin: Pin, title: String?, subtitle: String?) {
        self.pin = pin
        self.title = title
        self.subtitle = subtitle
    }
    
    
}