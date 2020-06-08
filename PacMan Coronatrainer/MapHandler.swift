////
////  MapHandler.swift
////  PacMan Coronatrainer
////
////  Created by Avikam on 5/27/20.
////  Copyright © 2020 Avikam Chauhan. All rights reserved.
////

import Foundation
import MapKit

class MapHandler: NSObject, LocationHandlerDelegate {
    
    var delegate: MapHandlerDelegate?
    
    static var pacManAnnotation: CustomAnnotation!
    static var ghostAnnotations: [CustomAnnotation] = []
    static var pinAnnotations: [CustomAnnotation] = []
    static var pinAnnotationView: MKPinAnnotationView!
    
    var currentWaypointIndex = 0
    var startingPoint = CLLocation()
    var waypoints = [CLLocation]()
    private var activeRouteTracking = false
    private var locationHandler = LocationHandler()
    
    override init() {
        super.init()
        locationHandler.delegate = self
    }
    
    // MARK: Custom Map Annotation Functions
    
    enum AnnotationType {
        case Pin
        case PacMan
        case Ghost
    }
    
    static func createAnnotation(ofType annotationType: AnnotationType, atCoordinate coordinate: CLLocationCoordinate2D) -> MKAnnotation {
        if annotationType == .PacMan {
            pacManAnnotation = CustomAnnotation()
            pacManAnnotation.pinCustomImageName = "pac-man"
            pacManAnnotation.coordinate = coordinate
            
            pinAnnotationView = MKPinAnnotationView(annotation: pacManAnnotation, reuseIdentifier: "pac-man")
            return pinAnnotationView.annotation!
        } else {
            var id = ""
            let annotation = CustomAnnotation()
            annotation.coordinate = coordinate
            if annotationType == .Pin {
                id = "flag"
                pinAnnotations.append(annotation)
            } else {
                id = "ghost-red"
                ghostAnnotations.append(annotation)
            }
            annotation.pinCustomImageName = id
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            return pinAnnotationView.annotation!
        }
    }
    
    // MARK: Maps Routing and Tracking Functions
    
    func addWaypoint(atLocation location: CLLocation) {
        waypoints.append(location)
    }
    
    func getDistance(fromStartingLocation startingLocation: CLLocation, toEndingLocation endingLocation: CLLocation, handler: @escaping (Double) -> ()) {
        getDirections(fromStartingLocation: startingLocation, toEndingLocation: endingLocation) { (response) in
            handler(response.routes.first!.distance)
        }
    }
    
    func getDirections(fromStartingLocation startingLocation: CLLocation, toEndingLocation endingLocation: CLLocation, handler: @escaping (MKDirections.Response) -> ()) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingLocation.coordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endingLocation.coordinate, addressDictionary: nil))
        request.requestsAlternateRoutes = false
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            guard let response = response else { return }
            handler(response)
        }
    }
    
    func getDirections(toDestinations destinations: [CLLocation], handler: @escaping ([MKDirections.Response]) -> ()) {
        var routes = [MKDirections.Response]()
        
        if destinations.count > 0 {
            var locations = destinations
            if let location = LocationHandler.getCurrentLocation() {
                locations.insert(location, at: 0)
                for i in 0..<destinations.count - 1 {
                    getDirections(fromStartingLocation: locations[i], toEndingLocation: locations[i + 1]) { (response) in
                        routes.append(response)
                    }
                }
            }
        }
    }
    
    func startActiveRouteTracking() {
        startingPoint = LocationHandler.getCurrentLocation()!
        activeRouteTracking = true
    }
    
    // MARK: LocationHandler Protocol Implementation
    
    func locationHandler(didUpdateCurrentLocation currentLocation: CLLocation?) {
        if activeRouteTracking {
            if (currentLocation?.distance(from: CLLocation(latitude: (waypoints[currentWaypointIndex - 1].coordinate.latitude), longitude: (waypoints[currentWaypointIndex].coordinate.longitude))))! < 5.0 {
                getDistance(fromStartingLocation: waypoints[currentWaypointIndex - 1], toEndingLocation: waypoints[currentWaypointIndex], handler: { (distance) in
                    //                    User.points += Int(50 * distance) / 1609.34
                })
                currentWaypointIndex += 1
            }
            getDirections(toDestinations: Array(waypoints[currentWaypointIndex..<waypoints.count])) { (routes) in
                self.delegate?.mapHandler(didUpdateRoutes: routes)
            }
        }
    }
    
    func locationHandler(didUpdateCurrentHeading currentHeading: CLHeading) {
        // do nothing
    }
}

protocol MapHandlerDelegate {
    
    func mapHandler(didUpdateRoutes routes: [MKDirections.Response])
    
}
