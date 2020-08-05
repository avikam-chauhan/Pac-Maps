//
//  ROute.swift
//  PacMan Coronatrainer
//
//  Created by Avikam on 7/30/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class Route {
    
    var startingLocation = CLLocation()
    var endingLocation = CLLocation()
    
    var route = MKRoute()
    var totalDistance = 0.0
    
    var coinLocations = [CLLocationCoordinate2D]() {
        didSet {
            for location in coinLocations {
                let annotation = CustomAnnotation(annotationType: .flag, location: CLLocation(latitude: location.latitude, longitude: location.latitude), UUID: "flag")
                coinAnnotations.append(annotation)
        
                let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "flag")
                coinAnnotationViews.append(pinAnnotationView)                
            }
        }
    }
    var coinAnnotations = [CustomAnnotation]()
    var coinAnnotationViews = [MKPinAnnotationView]()
    
    init (from startingLocation: CLLocation, to endingLocation: CLLocation, with route: MKRoute) {
        self.startingLocation = startingLocation
        self.endingLocation = endingLocation
        self.route = route
        self.totalDistance = route.distance
        self.interpolatePoints()
    }
    
    func interpolatePoints() {
        var newPoints = route.polyline.coordinates
        let polylineCoordinates = route.polyline.coordinates
        
//        for var i in 1..<polylineCoordinates.count {
//            let loc1 = CLLocation(latitude: polylineCoordinates[i - 1].latitude, longitude: polylineCoordinates[i - 1].longitude)
//            let loc2 = CLLocation(latitude: polylineCoordinates[i].latitude, longitude: polylineCoordinates[i].longitude)
//            if loc1.distance(from: loc2) > 30 {
//                //MARK: FIX IT
//                newPoints.insert(CLLocationCoordinate2D(latitude: (loc1.coordinate.latitude + loc2.coordinate.latitude) / 2, longitude: (loc1.coordinate.longitude + loc2.coordinate.longitude) / 2), at: i)
//                i -= 2
//            } else if loc1.distance(from: loc2) < 10 {
//                if i < newPoints.count {
//                    newPoints.remove(at: i)
//                }
//            }
//        }
        
        self.coinLocations = newPoints
    }
    
}
