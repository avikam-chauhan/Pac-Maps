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

class BluetoothHandler: NSObject, CLLocationManagerDelegate, CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    
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
    var centralManager: CBCentralManager!
    let BLE_UUID = "5DE63112-432E-4D11-AFDF-F6F091689061"
    var WR_UUID = CBUUID(string: "5DE63112-432E-4D11-AFDF-F6F091689061")
    let WR_PROPERTIES: CBCharacteristicProperties = .write
    let WR_PERMISSIONS: CBAttributePermissions = .writeable
    
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
        let localBeaconMajor: CLBeaconMajorValue = 1237
        
        let uuid = UUID(uuidString: BLE_UUID)
        print("minor of phone \(localBeaconMinor)")
        localBeacon = CLBeaconRegion(uuid: uuid!, major: localBeaconMajor, minor: localBeaconMinor, identifier: "Your private identifer here")
        beaconPeripheralData = localBeacon.peripheralData(withMeasuredPower: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    func stopLocalBeacon() {
        peripheralManager.stopAdvertising()
        peripheralManager = nil
        beaconPeripheralData = nil
        localBeacon = nil
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            
            let serialService = CBMutableService(type: CBUUID(string: BLE_UUID), primary: true)
            let writeCharacteristics = CBMutableCharacteristic(type: WR_UUID,
                                             properties: WR_PROPERTIES, value: nil,
                                             permissions: WR_PERMISSIONS)
            serialService.characteristics = [writeCharacteristics]
            peripheralManager.add(serialService)

            peripheralManager.startAdvertising(beaconPeripheralData as? [String: Any])
            let advertisementData = String(format: "%@", UIDevice.current.identifierForVendor!.uuidString)
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: BLE_UUID,
                                                CBAdvertisementDataLocalNameKey: advertisementData])
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
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let value = request.value {
                
                //here is the message text that we receive, use it as you wish.
                let messageText = String(data: value, encoding: String.Encoding.utf8) as! String
                print("MESSAGE TEXT RECEIVED: \(messageText)")
            }
            self.peripheralManager.respond(to: request, withResult: .success)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn) {
            
          //here we scan for the devices with a UUID that is specific to our app, which filters out other BLE devices.
            self.centralManager?.scanForPeripherals(withServices: [CBUUID(string: BLE_UUID)], options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Here we can read peripheral.identifier as UUID, and read our advertisement data by the key CBAdvertisementDataLocalNameKey.
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            let characteristic = characteristic as CBCharacteristic
            
            if characteristic.uuid.isEqual(WR_UUID) {
                let data = BLE_UUID.data(using: .utf8)
                peripheral.writeValue(data!, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                print("Sending Value \(data!)")
            }
        }
    }
    
}

protocol BluetoothHandlerDelegate {
    func didUpdateProximityToUser(distance: CLProximity, uuid: String)
}
