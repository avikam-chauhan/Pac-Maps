//
//  ViewController.swift
//  PacMan Coronatrainer
//
//  Created by Avikam on 4/24/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreBluetooth
import AudioToolbox
import Firebase

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, CBPeripheralManagerDelegate {
    
    var ref: DatabaseReference!
    var users = [User]()
    
    var vibrate = false
    
    func vibrateTimer(time: Double) {
        for i in 0...13 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(i) * time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                if self.vibrate {
                    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                }
            })
        }
    }
    
    //
    
    var removePointsTimer = Timer()
    var addPointsTimer = Timer()

    var pacManAnnotation: CustomAnnotation!
    var ghostAnnotation: [CustomAnnotation] = []
    var pinAnnotationView: MKPinAnnotationView!
    
    
    func showGhost(coordinate: CLLocationCoordinate2D) {
        var annotation = CustomAnnotation()
        annotation.pinCustomImageName = "ghost-red"
        annotation.coordinate = coordinate
        ghostAnnotation.append(annotation)
        
        var pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "ghost")
        mapView.addAnnotation(pinAnnotationView.annotation!)
    }
    
    func showFlag(coordinate: CLLocationCoordinate2D) {
        var annotation = CustomAnnotation()
        annotation.pinCustomImageName = "flag"
        annotation.coordinate = coordinate
        ghostAnnotation.append(annotation)
        
        var pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "flag")
        mapView.addAnnotation(pinAnnotationView.annotation!)
    }
    
    func showPacMan(coordinate: CLLocationCoordinate2D) {
        pacManAnnotation = CustomAnnotation()
        pacManAnnotation.pinCustomImageName = "pac-man"
        pacManAnnotation.coordinate = coordinate
        
        pinAnnotationView = MKPinAnnotationView(annotation: pacManAnnotation, reuseIdentifier: "pac-man")
        mapView.addAnnotation(pinAnnotationView.annotation!)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = "ghost"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        if let customPointAnnotation = annotation as? CustomAnnotation {
            annotationView?.image = UIImage(named: customPointAnnotation.pinCustomImageName)
        }
        annotationView?.transform = CGAffineTransform(scaleX: 0.005, y: 0.005)
        
        return annotationView
    }
    
    // MARK: iBeacon Stuff
    
    
    var beaconRegion: CLBeaconRegion! = nil
    var beaconPeripheralData: NSDictionary = NSDictionary()
    var peripheralManager: CBPeripheralManager = CBPeripheralManager()
    
    
    func initBeaconRegion() {
        beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: "E06F95E4-FCFC-42C6-B4F8-F6BAE87EA1A0")!, major: 1233, minor: 45, identifier: "PacMan")
        beaconPeripheralData = beaconRegion .peripheralData(withMeasuredPower: nil)
        peripheralManager = CBPeripheralManager.init(delegate: self, queue: nil)
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if (peripheral.state == .poweredOn) {
            peripheralManager .startAdvertising(beaconPeripheralData as? [String : Any])
            print("Powered On")
        } else {
            peripheralManager .stopAdvertising()
            print("Not Powered On, or some other error")
        }
    }
    
    func startScanningForBeaconRegion(beaconRegion: CLBeaconRegion) {
        print(beaconRegion)
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
    }
    
    
    @objc func subtract1() {
        if vibrate {
            points = points - 1
        }
    }
    
    @objc func add1() {
        if !vibrate {
            points = points + 1
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        var minProximity = CLProximity.far
        if beacons.count > 0 {
            for beacon in beacons {
                if beacon.proximity.rawValue < minProximity.rawValue {
                    minProximity = beacon.proximity
                }
            }
            UIView.animate(withDuration: 0.5, animations: {
                if minProximity == CLProximity.unknown {
                    self.safetyLabel.text = "SAFE"
                    self.topView.backgroundColor = UIColor.systemGreen
                    self.bottomView.backgroundColor = UIColor.systemGreen
                    self.vibrate = false
                    self.removePointsTimer.invalidate()
                } else if minProximity == CLProximity.immediate {
                    self.safetyLabel.text = "TOO CLOSE"
                    self.topView.backgroundColor = UIColor.systemRed
                    self.bottomView.backgroundColor = UIColor.systemRed
                    self.vibrate = true
                    self.vibrateTimer(time: 0.1)
                                        
                    self.removePointsTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(ViewController.subtract1), userInfo: nil, repeats: true)
                    self.removePointsTimer.fire()
                } else if minProximity == CLProximity.near {
                    self.safetyLabel.text = "NEAR"
                    self.topView.backgroundColor = UIColor.systemOrange
                    self.bottomView.backgroundColor = UIColor.systemOrange
                    self.vibrate = true
                    self.vibrateTimer(time: 1)

                    self.removePointsTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.subtract1), userInfo: nil, repeats: true)
                    self.removePointsTimer.fire()
                } else if minProximity == CLProximity.far {
                    self.safetyLabel.text = "CAUTION"
                    self.topView.backgroundColor = UIColor.systemYellow
                    self.bottomView.backgroundColor = UIColor.systemYellow
                    self.vibrate = false
                    self.removePointsTimer.invalidate()
                }
            })
        }
    }
    
    //
    
    var points: Int {
        set {
            pointsLabel.text = "\(newValue) •"
            FirebaseInterface.updateScore(score: newValue)
        }
        get {
            return FirebaseInterface.getScore()
        }
    }
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var safetyLabel: UILabel!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var rankingLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var routeLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    var currentLocation: CLLocation?
    var previousLocation: CLLocation?
    var currentHeading: CLHeading?
    
    let locationManager = CLLocationManager()
    
    var listeningForMapTap = false
    
    var currentWaypointIndex = 0
    var startingLocation: CLLocationCoordinate2D?
    var waypoints: [CLLocationCoordinate2D] = []
    var distances: [Double] = []
    var totalDistance = 0.0 {
        didSet {
            if totalDistance != 0.0 {
                routeLabel.text = " \((totalDistance / 1609.34).rounded(toPlaces: 1)) miles — \(Int(50 * totalDistance / 1609.34)) • "
            }
        }
    }
    
    
    
    
    
    func getAllUsers(handler: @escaping ([User]) -> ()) {
        var outputArray = [User]()
        ref.child("users").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            for key in value!.allKeys {
                
                //            print(key)
                if let userDictionary = value?.value(forKey: key as! String) as? NSDictionary {
                    let locationDictionary = userDictionary.value(forKey: "location") as? NSDictionary
                    //            print(userDictionary!["score"]!)
                    var tempUser = User(UUID: key as? String ?? "", score: userDictionary["score"] as? Int ?? 0, location: CLLocationCoordinate2D(latitude: CLLocationDegrees(locationDictionary?["latitude"] as? Double ?? 0), longitude: CLLocationDegrees(locationDictionary?["longitude"] as? Double ?? 0)), username: userDictionary["username"] as? String ?? "")
                    
                    outputArray.append(tempUser)
                }
            }
            handler(outputArray)
        })
        //        return outputArray
    }
    
    func parseUsers(dictionary: NSDictionary) -> [User]{
        var outputArray = [User]()
        let userDictionary = dictionary.value(forKey: "users") as? NSDictionary
        //        ref.child("users").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
        //            let value = snapshot.value as? NSDictionary
        for key in userDictionary!.allKeys {
            
            //            print(key)
            if let subDictionary = userDictionary!.value(forKey: key as! String) as? NSDictionary {
                let locationDictionary = subDictionary.value(forKey: "location") as? NSDictionary
                //            print(userDictionary!["score"]!)
                var tempUser = User(UUID: key as? String ?? "", score: subDictionary["score"] as? Int ?? 0, location: CLLocationCoordinate2D(latitude: CLLocationDegrees(locationDictionary?["latitude"] as? Double ?? 0), longitude: CLLocationDegrees(locationDictionary?["longitude"] as? Double ?? 0)), username: subDictionary["username"] as? String ?? "")
                
                outputArray.append(tempUser)
            }
        }
        return outputArray
        //            handler(outputArray)
        //        })
    }
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let launchedBefore = UserDefaults.standard.bool(forKey: "89aaa7987")
        if !launchedBefore {
            let alert = UIAlertController(title: "Welcome", message: "Please enter your username!", preferredStyle: UIAlertController.Style.alert)
            alert.addTextField(configurationHandler: nil)
            alert.addAction(UIAlertAction(title: "Let's play!", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                FirebaseInterface.createUser()
                FirebaseInterface.updateUsername(username: (alert.textFields?.first?.text!)!)
                FirebaseInterface.updateScore(score: 0)
            }))
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
            
            UserDefaults.standard.set(true, forKey: "89aaa7987")
        }
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation();
        locationManager.startUpdatingHeading();
        
        self.mapView.setUserTrackingMode(.followWithHeading, animated: true)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap))
        mapView.addGestureRecognizer(tapGesture)
        mapView.delegate = self
        
        self.addPointsTimer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(ViewController.add1), userInfo: nil, repeats: true)
        self.addPointsTimer.fire()

        
        //
        initBeaconRegion()
        startScanningForBeaconRegion(beaconRegion: CLBeaconRegion.init(proximityUUID: UUID.init(uuidString: "E06F95E4-FCFC-42C6-B4F8-F6BAE87EA1A0")!,
                                                                       identifier: "PacMan"))
        
        ref = Database.database().reference()
        getAllUsers { (users) in
            self.users = users
        }
        
        var refHandle = ref.observe(DataEventType.value, with: { (snapshot) in
            let postDict = snapshot.value as? NSDictionary
            self.users = self.parseUsers(dictionary: postDict!)
        })
        self.points = FirebaseInterface.getScore()
        
        self.getAllUsers { (myUsers) in
            var sortedUsers = myUsers.sorted(by: { (a, b) -> Bool in
                a.score > b.score
            })
            for x in 0..<sortedUsers.count {
                if sortedUsers[x].UUID == UIDevice.current.identifierForVendor!.uuidString {
                    self.rankingLabel.text = "#\(x+1)"
                    break
                }
            }
        }
        
    }
    
    
    
    @objc func tap(sender: UITapGestureRecognizer) {
        if listeningForMapTap {
            distances.removeAll()
            listeningForMapTap = false
            addButton.setTitleColor(UIColor.white, for: .normal)
            let coordinate = mapView.convert(sender.location(in: sender.view), toCoordinateFrom: sender.view)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            waypoints.append(coordinate)
            //            showFlag(coordinate: coordinate)
            
            totalDistance = 0.0
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation!.coordinate, addressDictionary: nil))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[0], addressDictionary: nil))
            request.requestsAlternateRoutes = false
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            
            directions.calculate { [unowned self] response, error in
                guard let unwrappedResponse = response else { return }
                
                for route in unwrappedResponse.routes {
                    self.mapView.addOverlay(route.polyline)
                    self.totalDistance += route.distance
                    self.distances.append(route.distance)
                }
            }
            
            for x in 0..<waypoints.count-1 {
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[x], addressDictionary: nil))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[x+1], addressDictionary: nil))
                request.requestsAlternateRoutes = false
                request.transportType = .walking
                
                let directions = MKDirections(request: request)
                
                directions.calculate { [unowned self] response, error in
                    guard let unwrappedResponse = response else { return }
                    
                    for route in unwrappedResponse.routes {
                        self.mapView.addOverlay(route.polyline)
                        self.totalDistance += route.distance
                        self.distances.append(route.distance)
                    }
                    print(self.distances)
                }
            }
        }
    }
    
    @IBAction func returnToCenter(_ sender: Any) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.mapView.setUserTrackingMode(.followWithHeading, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.yellow
        renderer.lineWidth = 8
        renderer.lineDashPattern = [0, 20]
        return renderer
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        if listeningForMapTap {
            listeningForMapTap = false
            addButton.setTitleColor(UIColor.white, for: .normal)
        } else {
            listeningForMapTap = true
            addButton.setTitleColor(UIColor.lightGray, for: .normal)
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //        if currentHeading == nil {
        //            mapView.centerToLocation(locations.first!)
        //        } else {
        //            mapView.setCamera(MKMapCamera(lookingAtCenter: locations.first!.coordinate, fromDistance: 500, pitch: 0, heading: currentHeading!.trueHeading), animated: true)
        //        }
        
        
        if startingLocation == nil {
            startingLocation = locations.first!.coordinate
        } else if waypoints.count > 0 {
            print((currentLocation?.distance(from: CLLocation(latitude: waypoints[currentWaypointIndex].latitude, longitude: waypoints[currentWaypointIndex].longitude)))!)
            if (currentLocation?.distance(from: CLLocation(latitude: waypoints[currentWaypointIndex].latitude, longitude: waypoints[currentWaypointIndex].longitude)))! < 5.0 {
                points += Int(50 * distances[currentWaypointIndex] / 1609.34)
                currentWaypointIndex += 1
            }
        }
//        previousLocation = currentLocation
        currentLocation = locations.first!
//        if previousLocation != nil && currentLocation != nil {
//            var delta = previousLocation!.distance(from: currentLocation!)
//            points += Int(50 * delta / 1609.34)
//        }
        self.mapView.removeAnnotations(mapView.annotations)
        showPacMan(coordinate: self.currentLocation!.coordinate)
        for user in self.users {
            if user.UUID != UIDevice.current.identifierForVendor!.uuidString {
                self.showGhost(coordinate: user.location!)
            }
        }
        FirebaseInterface.updateLocation(currentLocation: currentLocation!.coordinate)
        
        
        
        
        
        
        if self.waypoints.count > 0 {
            mapView.removeOverlays(mapView.overlays)
            
            totalDistance = 0.0
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation!.coordinate, addressDictionary: nil))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[0], addressDictionary: nil))
            request.requestsAlternateRoutes = false
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            
            directions.calculate { [unowned self] response, error in
                guard let unwrappedResponse = response else { return }
                
                for route in unwrappedResponse.routes {
                    self.mapView.addOverlay(route.polyline)
                    self.totalDistance += route.distance
                    self.distances.append(route.distance)
                }
            }
            
            for x in 0..<waypoints.count-1 {
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[x], addressDictionary: nil))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[x+1], addressDictionary: nil))
                request.requestsAlternateRoutes = false
                request.transportType = .walking
                
                let directions = MKDirections(request: request)
                
                directions.calculate { [unowned self] response, error in
                    guard let unwrappedResponse = response else { return }
                    
                    for route in unwrappedResponse.routes {
                        self.mapView.addOverlay(route.polyline)
                        self.totalDistance += route.distance
                        self.distances.append(route.distance)
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        //        mapView.setCamera(MKMapCamera(lookingAtCenter: currentLocation!.coordinate, fromDistance: 500, pitch: 0, heading: newHeading.trueHeading), animated: true)
        currentHeading = newHeading
    }
    
    @IBAction func tappedBottom1(_ sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "toLeaderboard", sender: self)
    }
    
    @IBAction func tappedBottom2(_ sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "toLeaderboard", sender: self)
    }
    
}

private extension MKMapView {
    func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 250) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
    }
}

extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
