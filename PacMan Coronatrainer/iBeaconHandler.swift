//
//  iBeaconHandler.swift
//  BLEDataTransfer
//
//  Created by Mihir Chauhan on 6/5/20.
//  Copyright © 2020 Mihir Chauhan. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth
import UIKit
import AudioToolbox

class iBeaconHandler: NSObject, CLLocationManagerDelegate, CBPeripheralManagerDelegate {
    
    var locationManager: CLLocationManager?
    var localBeacon: CLBeaconRegion!
    var beaconPeripheralData: NSDictionary!
    var peripheralManager: CBPeripheralManager!
    let radarImageView: UIImageView = UIImageView(frame: CGRect(x: 50, y: 100, width: 300, height: 300))
    var totalPeopleOnRadar = 1
    var isCheckingForFamilyMember: Bool = false
    var closestBeaconMinorKey: Int = 0
    var familyMemberUUID: String = ""
    var uuidAsData: Data = Data(UIDevice.current.identifierForVendor!.uuidString.utf8)
    var localBeaconMinor: CLBeaconMinorValue = 0 {
        didSet {
            initLocalBeacon()
        }
    }
    let BLE_UUID = "5DE63112-432E-4D11-AFDF-F6F091689061"
    var WR_UUID = CBUUID(string: "5DE63112-432E-4D11-AFDF-F6F091689061")
    let WR_PROPERTIES: CBCharacteristicProperties = .write
    let WR_PERMISSIONS: CBAttributePermissions = .writeable
    
    var topToolbar: UIView!
    var distanceReading: UILabel!
    var bottomView: UIView!
    var beaconHandlerDelegate: iBeaconHandlerDelegate?
    
    
    public func startBeacon() {
        isCheckingForFamilyMember = false
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization() //can be when in
        locationManager?.startUpdatingHeading()
        
        self.localBeaconMinor = 1
        
    }
    
    public func exchageFamilyUUID() {
        //let alert = UIAlertController(title: "Add Family Member", message: "Move your phone right next to your family member's phone.", preferredStyle: UIAlertController.Style.alert)
        
        //alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { _ in
        //Cancel Action
        //}))
        //alert.addAction(UIAlertAction(title: "Done",
        //                              style: UIAlertAction.Style.default,
        //                             handler: {(_: UIAlertAction!) in
        //                                self.isCheckingForFamilyMember = true
        //}))
        
        //self.present(alert, animated: true, completion: nil)
        
        //print("Closest Beacon Minor Key: \(closestBeaconMinorKey)")
        
//        FirebaseInterface.getUserDatabase { (dict) in
//            self.familyMemberUUID = FirebaseInterface.searchUUID(dictionary: dict, minorKey: self.closestBeaconMinorKey) ?? ""
//        }
    }
    
    //MARK: BEACON MISC CODE
    
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
    
    var removePointsTimer = Timer()
    
    
    
    
    //MARK: BEACON TRANSMITTING
    
    func initLocalBeacon() {
        if localBeaconMinor == 0 {
            localBeaconMinor = CLBeaconMinorValue(1)
        }
        
        if localBeacon != nil {
            stopLocalBeacon()
        }
        let localBeaconMajor: CLBeaconMajorValue = 1237
        
        let uuid = UUID(uuidString: BLE_UUID)
        print("minor of phone \(localBeaconMinor)")
        localBeacon = CLBeaconRegion(uuid: uuid!, major: localBeaconMajor, minor: localBeaconMinor, identifier: "Pac-Maps")
        beaconPeripheralData = localBeacon.peripheralData(withMeasuredPower: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    func stopLocalBeacon() {
        peripheralManager.stopAdvertising()
        peripheralManager = nil
        beaconPeripheralData = nil
        localBeacon = nil
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            peripheralManager.startAdvertising(beaconPeripheralData as? [String: Any])
        } else if peripheral.state == .poweredOff {
            peripheralManager.stopAdvertising()
        }
    }
    
    
    
    //MARK: BEACON DETECTION
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways { //can be when in use..
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    startScanning()
                }
            }
        }
    }
    
    func startScanning() {
        let beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: BLE_UUID)!, major: CLBeaconMajorValue(1237), identifier: "MyBeacon")
        
        locationManager?.startMonitoring(for: beaconRegion)
        locationManager?.startRangingBeacons(in: beaconRegion)
    }
    
    func update(distance: CLProximity) {
        UIView.animate(withDuration: 0.5) {
            if self.isCheckingForFamilyMember {
                switch distance {
                case .immediate:
                    self.topToolbar.backgroundColor = .systemTeal
                    self.distanceReading.text = "FAMILY MEMBER DETECTED"
                    //FirebaseInterface.addAFamilyMember(familyMemberMinorKey: self.closestBeaconMinorKey)
                    //FirebaseInterface.updateFamilyMemberFamilyMembers(familyMemberUUID: self.familyMemberUUID)
                    self.isCheckingForFamilyMember = false
                case .near: return
                case .far: return
                default: return
                }
            } else {
                switch distance {
                case .immediate:
                    print("immediate")
                    self.distanceReading.text = "TOO CLOSE!"
                    self.topToolbar.backgroundColor = .systemRed
                    self.bottomView.backgroundColor = .systemRed
                    self.vibrate = true
                    self.vibrateTimer(time: 0.1)
                    self.removePointsTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(ViewController.subtract1), userInfo: nil, repeats: true)
                    self.removePointsTimer.fire()
                case .near:
                    print("near")
                    self.topToolbar.backgroundColor = .systemOrange
                    self.bottomView.backgroundColor = .systemOrange
                    self.distanceReading.text = "NEAR"
                    self.vibrate = true
                    self.vibrateTimer(time: 1)
                    self.removePointsTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.subtract1), userInfo: nil, repeats: true)
                    self.removePointsTimer.fire()
                case .far:
                    print("far")
                    self.topToolbar.backgroundColor = .systemYellow
                    self.distanceReading.text = "CAUTION"
                    self.bottomView.backgroundColor = UIColor.systemYellow
                    self.vibrate = false
                    self.removePointsTimer.invalidate()
                default:
                    self.topToolbar.backgroundColor = .systemGreen
                    self.distanceReading.text = "SAFE"
                    self.bottomView.backgroundColor = UIColor.systemGreen
                    self.vibrate = false
                    self.removePointsTimer.invalidate()
                }
            }
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        var maxProximity = CLProximity.far
        for beacon in beacons {
            print("\(beacon.uuid), \(beacon.major), \(beacon.minor)")
            if beacon.proximity.rawValue < maxProximity.rawValue {
                maxProximity = beacon.proximity
                closestBeaconMinorKey = Int(truncating: beacon.minor)
                beaconHandlerDelegate?.didUpdateProximityToUser(distance: beacon.proximity, uuid: "")
            }
        }
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        var maxProximity = CLProximity.far
        for beacon in beacons {
            if beacon.proximity.rawValue < maxProximity.rawValue {
                maxProximity = beacon.proximity
                closestBeaconMinorKey = Int(truncating: beacon.minor)
            }
        }
        
        //call func to add family member key
        update(distance: maxProximity)
        
        
    }
    
    init(topBar: UIView, bottomBar: UIView, distanceReading: UILabel) {
        topToolbar = topBar
        bottomView = bottomBar
        self.distanceReading = distanceReading
    }
    

}

protocol iBeaconHandlerDelegate {
    func didUpdateProximityToUser(distance: CLProximity, uuid: String)
}

