//
//  BluetoothHandler.swift
//  PacMan Coronatrainer
//
//  Created by Mihir Chauhan on 5/27/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth
import UIKit

class BluetoothHandler: NSObject, CLLocationManagerDelegate, CBPeripheralManagerDelegate {
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
    
    @IBOutlet weak var topToolbar: UIView!
    @IBOutlet weak var distanceReading: UILabel!
    var bluetoothDelegate: BluetoothHandlerDelegate?
    
    
    public func startBeacon() {
        isCheckingForFamilyMember = false
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization() //can be when in
        locationManager?.startUpdatingHeading()
        
        FirebaseInterface.doesHaveMinorKey { (exists) in
            print(exists)
            if !exists {
                FirebaseInterface.getuserCount { (userCount) in
                    self.localBeaconMinor = CLBeaconMinorValue(userCount)
                    print("MINOR KEY SET FOR THIS PHONE \(userCount)")
                    FirebaseInterface.updateMinorKey(minorKey: userCount)
                }
            } else {
                FirebaseInterface.getCurrentMinorkey { (currentMinorKey) in
                    self.localBeaconMinor = CLBeaconMinorValue(currentMinorKey)
                    print("MINOR KEY FOR THIS PHONE \(currentMinorKey)")
                    FirebaseInterface.updateMinorKey(minorKey: currentMinorKey)
                }
            }
        }
        
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
        FirebaseInterface.getUserDatabase { (dict) in
            self.familyMemberUUID = FirebaseInterface.searchUUID(dictionary: dict, minorKey: self.closestBeaconMinorKey) ?? ""
        }
    }
    
    
    
    //MARK: BEACON TRANSMITTING
    
    func initLocalBeacon() {
        if localBeaconMinor == 0 {
            localBeaconMinor = CLBeaconMinorValue(1)
        }
        
        if localBeacon != nil {
            stopLocalBeacon()
        }
        let localBeaconUUID = "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5"
        let localBeaconMajor: CLBeaconMajorValue = 1237
        
        let uuid = UUID(uuidString: localBeaconUUID)
        print("minor of phone \(localBeaconMinor)")
        localBeacon = CLBeaconRegion(uuid: uuid!, major: localBeaconMajor, minor: localBeaconMinor, identifier: "Your private identifer here")
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
        let localBeaconUUID = "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5"
        let beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: localBeaconUUID)!, major: CLBeaconMajorValue(1237), identifier: "MyBeacon")
        
        locationManager?.startMonitoring(for: beaconRegion)
        locationManager?.startRangingBeacons(in: beaconRegion)
    }
    
    func update(distance: CLProximity) {
        UIView.animate(withDuration: 1) {
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
                    self.topToolbar.backgroundColor = .red
                    self.distanceReading.text = "RUN AWAY!"
                case .near:
                    self.topToolbar.backgroundColor = .systemOrange
                    self.distanceReading.text = "NEAR"
                case .far:
                    self.topToolbar.backgroundColor = .systemGreen
                    self.distanceReading.text = "SAFE"
                default:
                    self.topToolbar.backgroundColor = .systemGreen
                    self.distanceReading.text = "SAFE"
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
                closestBeaconMinorKey = Int(beacon.minor)
                bluetoothDelegate?.didUpdateProximityToUser(distance: beacon.proximity, uuid: "")
            }
        }
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        //        coordinateInfo.text = "\(round(locationManager?.location?.coordinate.latitude ?? nil!)), \(round(locationManager?.location?.coordinate.longitude ?? nil!)), \(round(locationManager?.heading?.trueHeading ?? nil!))"
        
        var maxProximity = CLProximity.far
        for beacon in beacons {
            if beacon.proximity.rawValue < maxProximity.rawValue {
                maxProximity = beacon.proximity
                closestBeaconMinorKey = Int(beacon.minor)
            }
        }
        
        //call func to add family member key
        update(distance: maxProximity)
        
        
    }
    
    //MARK: Send UUID over Bluetooth
    
    private func transmitUUID() {
        
    }
    
    private func recieveUUID() {
        
    }
    
    func extract() -> Data? {
        guard uuidAsData.count > 0 else {
            return nil
        }
        var range:Range<Data.Index>
        // Create a range based on the length of data to return
        if (uuidAsData.count) >= 180{
            range = (0..<180)
        }
        else{
            range = (0..<(uuidAsData.count))
        }
        // Get a new copy of data
        let subData = uuidAsData.subdata(in: range)
        // Mutate data
        uuidAsData.removeSubrange(range)
        // Return the new copy of data
        return subData
    }
    
    func sendData() {
        var characteristic: CBMutableCharacteristic?
        var sentDataPacket = extract()
        if sentDataPacket != nil {
            CBPeripheral?.writeValue(sentDataPacket!, for: characteristic!, type: .withoutResponse)
        }
        else{
            peripheralManager?.writeValue(kEndFileFlag.data(using: String.Encoding.utf8)!, for: characteristic!, type: .withoutResponse)
        }
    }
    
    
    
}

protocol BluetoothHandlerDelegate {
    func didUpdateProximityToUser(distance: CLProximity, uuid: String)
}
