//
//  MapHandler.swift
//  PacMan Coronatrainer
//
//  Created by Avikam on 5/27/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import Foundation
import CoreLocation

class LocationHandler: NSObject, CLLocationManagerDelegate {
    
    internal var locationManager: CLLocationManager?
    static var lastUpdatedLocation: CLLocation?
    static var lastUpdatedHeading: CLHeading?
    
    var delegate: LocationHandlerDelegate?
    
    override init() {
        super.init()
        
        let locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    
    func startLocationUpdates() {
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation();
        locationManager?.startUpdatingHeading();
    }
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        LocationHandler.lastUpdatedHeading = newHeading
        delegate?.locationHandler(didUpdateCurrentHeading: newHeading)
    }
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        LocationHandler.lastUpdatedLocation = locations.first
        delegate?.locationHandler(didUpdateCurrentLocation: locations.first)
    }
    
    static func getCurrentLocation() -> CLLocation? {
        return self.lastUpdatedLocation
    }
    
    static func getCurrentHeading() -> CLHeading? {
        return self.lastUpdatedHeading
    }
    
}

protocol LocationHandlerDelegate {
    
    func locationHandler(didUpdateCurrentLocation currentLocation: CLLocation?)
    
    func locationHandler(didUpdateCurrentHeading currentHeading: CLHeading)
    
}

