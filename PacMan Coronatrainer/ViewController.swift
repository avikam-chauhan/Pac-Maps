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

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, BluetoothHandlerDelegate, FirebaseInterfaceDelegate {
    
    // MARK: CoreLocation
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first!
        if let coordinate = self.currentLocation?.coordinate {
            self.pacManAnnotation.coordinate = coordinate
        }
        for user in self.users {
            if user.UUID != UIDevice.current.identifierForVendor!.uuidString {
                if let index = self.ghostAnnotation.firstIndex(where: {(annotation) -> Bool in annotation.UUID == user.UUID }) {
                    self.ghostAnnotation[index].coordinate = CLLocationCoordinate2D(latitude: user.location!.latitude, longitude: user.location!.longitude)
                } else {
                    let annotation = CustomAnnotation(annotationType: .ghost_red, location: CLLocation(latitude: user.location!.latitude, longitude: user.location!.longitude), UUID: user.UUID)
                    ghostAnnotation.append(annotation)
                    
                    let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "ghost")
                    mapView.addAnnotation(pinAnnotationView.annotation!)
                }
            }
        }
        FirebaseInterface.updateLocation(currentLocation: currentLocation!.coordinate)
        
        if let endingLocation = self.routes.first?.endingLocation {
            var coordinateToRemove: CLLocationCoordinate2D?
            if (currentLocation?.distance(from: endingLocation))! < 5.0 {
                self.points = self.points + Int(1000 * self.routes.first!.totalDistance / 1609.34)
                coordinateToRemove = self.routes.first!.route.polyline.coordinate
                self.routes.remove(at: 0)
            }
            
            let endingLocation = self.routes.first?.endingLocation
            let startingLocation = self.currentLocation
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingLocation!.coordinate, addressDictionary: nil))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endingLocation!.coordinate, addressDictionary: nil))
            request.requestsAlternateRoutes = false
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            directions.calculate { [unowned self] response, error in
                guard let unwrappedResponse = response else {
                    return
                }
                for route in unwrappedResponse.routes {
                    for overlay in self.mapView.overlays {
                        if overlay.coordinate.latitude == self.routes.first?.route.polyline.coordinate.latitude && overlay.coordinate.longitude == self.routes.first?.route.polyline.coordinate.longitude {
                            self.mapView.removeOverlay(overlay)
                        } else if let secondCoordinate = coordinateToRemove {
                            if overlay.coordinate.latitude == secondCoordinate.latitude && overlay.coordinate.longitude == secondCoordinate.longitude {
                                self.mapView.removeOverlay(overlay)
                            }
                        }
                    }
                    self.mapView.addOverlay(route.polyline)
                    if self.routes.count > 0 {
                        self.routes[0].route = route
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading
    }
    
    // MARK: MapKit
    
    var pacManAnnotation: CustomAnnotation!
    var ghostAnnotation: [CustomAnnotation] = []
    var flagAnnotation: [CustomAnnotation] = []
    var pinAnnotationView: MKPinAnnotationView!
    
    var routes: [Route] = []
    
    var currentLocation: CLLocation?
    var previousLocation: CLLocation?
    var currentHeading: CLHeading?
    
    let locationManager = CLLocationManager()
    
    var listeningForMapTap = false
    
    var totalDistance = 0.0 {
        didSet {
            if totalDistance != 0.0 {
                routeLabel.text = " \((totalDistance / 1609.34).rounded(toPlaces: 1)) miles — \(Int(1000 * totalDistance / 1609.34)) • "
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = (annotation as? CustomAnnotation)?.pinCustomImageName ?? "flag" // "ghost"
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
    
    @IBAction func clearRoutePressed(_ sender: Any) {
        self.routes.removeAll()
        totalDistance = 0
        mapView.removeOverlays(mapView.overlays)
        routeLabel.text = " 0 miles — 0 • "
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
    
    @objc func tap(sender: UITapGestureRecognizer) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        let coordinate = mapView.convert(sender.location(in: sender.view), toCoordinateFrom: sender.view)
        let endingLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        var startingLocation = self.currentLocation
        if self.routes.count > 0 {
            startingLocation = self.routes.last!.endingLocation
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingLocation!.coordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endingLocation.coordinate, addressDictionary: nil))
        request.requestsAlternateRoutes = false
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else {
                DispatchQueue.main.async {
                    if let mke = error as? MKError {
                        switch mke.errorCode {
                        case Int(MKError.Code.loadingThrottled.rawValue):
                            let alert = UIAlertController(title: "Please Try Again Later", message: "You have used too many routing requests in a short amount of time. Please wait for \((mke.errorUserInfo["MKErrorGEOErrorUserInfo"] as! NSDictionary)["timeUntilReset"]!) seconds.", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        default:
                            let alert = UIAlertController(title: "Walking Directions Not Available", message: "Walking directions are not available for this location.\nError: \(error!.localizedDescription)", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
                return
            }
            
            for route in unwrappedResponse.routes {
                self.mapView.addOverlay(route.polyline)
                //print(route.advisoryNotices, route.steps)
                let route2 = Route(from: startingLocation!, to: endingLocation, with: route)
                self.routes.append(route2)
                for view in route2.coinAnnotationViews {
                    self.mapView.addAnnotation(view.annotation!)
                }
                self.totalDistance += route.distance
            }
        }
    }

    //  MARK: CoreBluetooth and Proximity
    
    var bluetoothHandler: BluetoothHandler!
    
    var vibrate = false
    
    var recentDistance: CLProximity = .unknown {
        didSet {
            if isWaitingForRecentDistanceToBeSet {
                addContactedUserToFirebase(otherUserUUID: contactedUserUUID == "" ? nil : contactedUserUUID)
                isWaitingForRecentDistanceToBeSet = false
            }
        }
    }
    
    func didUpdate(points: Int, uuid: String) {
        if uuid == UIDevice.current.identifierForVendor!.uuidString {
            //print("setting your score")
            self.points = points
        } else {
            //print("setting other phone score")
            FirebaseInterface.setScore(forUUID: uuid, newScore: points)
        }
    }
    
    var contactedUserUUID: String = ""
    var isWaitingForRecentDistanceToBeSet: Bool = false
    
    var removePointsTimer: Timer?
    var addPointsTimer = Timer()
    
    func vibrateTimer(time: Double) {
        for i in 0...13 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(i) * time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                if self.vibrate {
                    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                }
            })
        }
    }
    
    func didUpdateBluetooth(distance: CLProximity) {
        UIView.animate(withDuration: 0.5, animations: {
            self.recentDistance = distance
            switch(distance) {
            case .unknown:
                self.navigationItem.title = "SAFE"
                self.navigationController?.navigationBar.barTintColor = UIColor.systemGreen
                self.bottomView.backgroundColor = UIColor.systemGreen
                self.vibrate = false
                self.removePointsTimer?.invalidate()
            case .immediate:
                self.navigationItem.title = "TOO CLOSE"
                self.navigationController?.navigationBar.barTintColor = UIColor.systemRed
                self.bottomView.backgroundColor = UIColor.systemRed
                self.vibrate = true
                self.vibrateTimer(time: 0.1)
                
                guard self.removePointsTimer == nil else { return }
                self.removePointsTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.subtract50), userInfo: nil, repeats: true)
                self.removePointsTimer?.fire()
                
            case .near:
                self.navigationItem.title = "NEAR"
                self.navigationController?.navigationBar.barTintColor = UIColor.systemOrange
                self.bottomView.backgroundColor = UIColor.systemOrange
                self.vibrate = true
                self.vibrateTimer(time: 1)
                
                guard self.removePointsTimer == nil else { return }
                self.removePointsTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.subtract50), userInfo: nil, repeats: true)
                self.removePointsTimer?.fire()
            case .far:
                self.navigationItem.title = "CAUTION"
                self.navigationController?.navigationBar.barTintColor = UIColor.systemYellow
                self.bottomView.backgroundColor = UIColor.systemYellow
                self.vibrate = false
                
                guard self.removePointsTimer == nil else { return }
                self.removePointsTimer?.invalidate()
                self.removePointsTimer = nil
            @unknown default:
                self.navigationItem.title = "SAFE"
                self.navigationController?.navigationBar.barTintColor = UIColor.systemGreen
                self.bottomView.backgroundColor = UIColor.systemGreen
                self.vibrate = false
                
                guard self.removePointsTimer == nil else { return }
                self.removePointsTimer?.invalidate()
                self.removePointsTimer = nil
            }
        })
    }
    
    func didUpdateBluetooth(timeInContact: Int) {
        FirebaseInterface.addTimeInContactToLastContactedUser(timeInContact: timeInContact)
    }
    
    func didUpdateBluetooth(otherUserUUID: String) {
        contactedUserUUID = otherUserUUID
        isWaitingForRecentDistanceToBeSet = true
        addContactedUserToFirebase(otherUserUUID: otherUserUUID)
    }
    
    // MARK: Firebase and User Info
    
    var firebaseInterface: FirebaseInterface!
    var ref: DatabaseReference!
    var users = [User]()
    var familyMemberUUIDs = Array<String>()
    var uuid: UUID? = nil
    
    var points: Int {
        set {
            if newValue > 1000000 {
                let numToShow: Double = Double(newValue) / 1000000.0
                pointsLabel.text = "\(numToShow.rounded(toPlaces: 2))M •"
            } else if newValue > 1000 {
                let numToShow: Double = Double(newValue) / 1000.0
                pointsLabel.text = "\(numToShow.rounded(toPlaces: 2))K •"
            } else {
                pointsLabel.text = "\(newValue) •"
            }
            if newValue != points {
                FirebaseInterface.updateScore(score: newValue)
            }
        }
        get {
            return FirebaseInterface.getScore(database: FirebaseInterface.dict) ?? 0
        }
    }
    
    func getAllUsers(handler: @escaping ([User]) -> ()) {
        var outputArray = [User]()
        ref.child("users").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            for key in value!.allKeys {
                
                //            //print(key)
                if let userDictionary = value?.value(forKey: key as! String) as? NSDictionary {
                    let locationDictionary = userDictionary.value(forKey: "location") as? NSDictionary
                    //            //print(userDictionary!["score"]!)
                    let tempUser = User(UUID: key as? String ?? "", score: userDictionary["score"] as? Int ?? 0, location: CLLocationCoordinate2D(latitude: CLLocationDegrees(locationDictionary?["latitude"] as? Double ?? 0), longitude: CLLocationDegrees(locationDictionary?["longitude"] as? Double ?? 0)), username: userDictionary["username"] as? String ?? "")
                    
                    outputArray.append(tempUser)
                }
            }
            handler(outputArray)
        })
    }
    
    func parseUsers(dictionary: NSDictionary) -> [User]{
        var outputArray = [User]()
        let userDictionary = dictionary.value(forKey: "users") as? NSDictionary
        for key in userDictionary!.allKeys {
            if let subDictionary = userDictionary!.value(forKey: key as! String) as? NSDictionary {
                let locationDictionary = subDictionary.value(forKey: "location") as? NSDictionary
                let tempUser = User(UUID: key as? String ?? "", score: subDictionary["score"] as? Int ?? 0, location: CLLocationCoordinate2D(latitude: CLLocationDegrees(locationDictionary?["latitude"] as? Double ?? 0), longitude: CLLocationDegrees(locationDictionary?["longitude"] as? Double ?? 0)), username: subDictionary["username"] as? String ?? "")
                outputArray.append(tempUser)
            }
        }
        return outputArray
    }
    
    func addContactedUserToFirebase(otherUserUUID: String?) {
        if otherUserUUID != nil {
            switch recentDistance {
                case .immediate:
                    FirebaseInterface.addContacteduserUUID(UUID: otherUserUUID!, Distance: "Immediate")
                    isWaitingForRecentDistanceToBeSet = false
                    contactedUserUUID = ""
                case .near:
                    FirebaseInterface.addContacteduserUUID(UUID: otherUserUUID!, Distance: "Near")
                    isWaitingForRecentDistanceToBeSet = false
                    contactedUserUUID = ""
                case .far:
                    //print("Recent distance is far")
                    return
                case .unknown:
                    //print("Recent distance is unknwon");
                    return
                default:
                    //print("RecentDistance Not set")
                    return
            }
        }
    }
    
    // MARK: UI
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var rankingLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var routeLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func showTutorial() {
        self.performSegue(withIdentifier: "toTutorial", sender: self)
    }
    
    @IBAction func tappedBottom1(_ sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "toLeaderboard", sender: self)
    }
    
    @IBAction func tappedBottom2(_ sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "toLeaderboard", sender: self)
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?){
        if motion == .motionShake {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Warning", message: "You are about to remove the last waypoint. Are you sure you want to do this?", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
                    DispatchQueue.main.async {
                        for _ in 0..<2 {
                            if self.routes.count > 0 {
                                self.routes.removeLast()
                                self.mapView.removeOverlays(self.mapView.overlays)
                                self.totalDistance = 0
                                for route in self.routes {
                                    self.mapView.addOverlay(route.route.polyline)
                                    self.totalDistance += route.route.distance
                                }
                            }
                        }
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func close(bySegue: UIStoryboardSegue) {
        let mvcUnwoundFrom = bySegue.source as? ScanQRCodeViewController
        if let uuid = (mvcUnwoundFrom?.uuid) {
            firebaseInterface.restorePoints(forUUID: uuid, withContactUUID: UUID(uuidString: UIDevice.current.identifierForVendor!.uuidString)!)
            firebaseInterface.restorePoints(forUUID: UUID(uuidString: UIDevice.current.identifierForVendor!.uuidString)!, withContactUUID: uuid)
            familyMemberUUIDs.append(uuid.uuidString)
            FirebaseInterface.addFamilyMember(uuid: uuid.uuidString)
            FirebaseInterface.addFamilyMemberToPlayer(withUUID: uuid)
            //print("fmuuids: \(familyMemberUUIDs)")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if !delegate.didSegue {
            delegate.didSegue = true
//            self.showTutorial()
        }
        self.navigationController?.navigationBar.barTintColor = UIColor.systemGreen
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        self.navigationController?.navigationBar.barTintColor = UIColor.systemGreen
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let launchedBefore = UserDefaults.standard.bool(forKey: "gdsagsdgasdfsadf")
        if !launchedBefore {
            let alert = UIAlertController(title: "Welcome", message: "Please enter your username!", preferredStyle: UIAlertController.Style.alert)
            alert.addTextField(configurationHandler: nil)
            alert.addAction(UIAlertAction(title: "Let's play!", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                FirebaseInterface.updateUsername(username: (alert.textFields?.first?.text!)!)
                FirebaseInterface.updateScore(score: 0)
            }))
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
            FirebaseInterface.updateUsername(username: "USER_\(random(digits: 4))\(random(digits: 3))\(random(digits: 3))")
            FirebaseInterface.updatePositiveResult(value: false)
            UserDefaults.standard.set(true, forKey: "gdsagsdgasdfsadf")
        }
        
        self.pacManAnnotation = CustomAnnotation(annotationType: .pac_man, location: self.currentLocation ?? CLLocation(latitude: 0, longitude: 0), UUID: "ME")
        
        pinAnnotationView = MKPinAnnotationView(annotation: self.pacManAnnotation, reuseIdentifier: "pac-man")
        self.mapView.addAnnotation(pinAnnotationView.annotation!)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation();
        locationManager.startUpdatingHeading();
        
        self.mapView.setUserTrackingMode(.followWithHeading, animated: true)
        
        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(tap))
        mapView.addGestureRecognizer(tapGesture)
        mapView.delegate = self
        
        FirebaseInterface.getUserDatabase { (dict, score) in
            self.points = score
        }
        
        ref = Database.database().reference()
        getAllUsers { (users) in
            self.users = users
        }
        
        _ = ref.observe(DataEventType.value, with: { (snapshot) in
            let postDict = snapshot.value as? NSDictionary
            self.users = self.parseUsers(dictionary: postDict!)
        })
        
        self.getAllUsers { (myUsers) in
            let sortedUsers = myUsers.sorted(by: { (a, b) -> Bool in
                a.score > b.score
            })
            for x in 0..<sortedUsers.count {
                if sortedUsers[x].UUID == UIDevice.current.identifierForVendor!.uuidString {
                    self.rankingLabel.text = "#\(x+1)"
                    break
                }
            }
        }
        
        FirebaseInterface.getFamilyMembers { (familyMembers) in
            if familyMembers != nil {
                for familyMember in 0..<(familyMembers?.count)! {
                    self.familyMemberUUIDs.append((familyMembers?[familyMember])!)
                }
            }
        }
        
        firebaseInterface = FirebaseInterface()
        FirebaseInterface.firebaseInterfaceDelegate = self
        
        bluetoothHandler = BluetoothHandler()
        bluetoothHandler.bluetoothHandlerDelegate = self
        bluetoothHandler.startSendReceivingBluetoothData()
    }
    
    @objc func subtract50() {
        if vibrate {
            points = points - 50
        }
    }
    
    func random(digits:Int) -> String {
        var number = String()
        for _ in 1...digits {
            number += "\(Int.random(in: 1...9))"
        }
        return number
    }
}

private extension MKMapView {
    func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 250) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension MKMultiPoint {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
