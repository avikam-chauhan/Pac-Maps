//
//  MapHandler.swift
//  PacMan Coronatrainer
//
//  Created by Avikam on 5/27/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import Foundation
import MapKit

class MapHandler: NSObject, LocationHandlerDelegate {
    
    var delegate: MapHandlerDelegate?
    
    var currentWaypointIndex = 0
    var startingPoint = CLLocation()
    var waypoints = [CLLocation]()
    private var activeRouteTracking = false
    private var locationHandler = LocationHandler()
    
    override init() {
        super.init()
        locationHandler.delegate = self
    }
    
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
    
    func didUpdateCurrentLocation(currentLocation: CLLocation?) {
        if activeRouteTracking {
            if (currentLocation?.distance(from: CLLocation(latitude: (waypoints[currentWaypointIndex].coordinate.latitude), longitude: (waypoints[currentWaypointIndex].coordinate.longitude))))! < 5.0 {
                getDistance(fromStartingLocation: waypoints[currentWaypointIndex - 1]), toEndingLocation: <#T##CLLocation#>, handler: { (distance) in
                    User.points += Int(50 * distance) / 1609.34
                })
                currentWaypointIndex += 1
            }
            getDirections(toDestinations: Array(waypoints[currentWaypointIndex..<waypoints.count])) { (routes) in
                delegate?.mapHandler(didUpdateRoutes: routes)
            }
        }
    }
    
    func didUpdateCurrentHeading(currentHeading: CLHeading) {
        // do nothing
    }
    
}

protocol MapHandlerDelegate {
    
    func mapHandler(didUpdateRoutes routes: [MKDirections.Response])
    
}
