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
//        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    func stopLocalBeacon() {
        peripheralManager.stopAdvertising()
        peripheralManager = nil
        beaconPeripheralData = nil
        localBeacon = nil
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("blajfajsdfsdfjhsdkjfkfkdhfkjhflkjsdflkfjwejfw")
        if peripheral.state == .poweredOn {
            
//            let serialService = CBMutableService(type: CBUUID(string: BLE_UUID), primary: true)
//            let writeCharacteristics = CBMutableCharacteristic(type: WR_UUID,
//                                             properties: WR_PROPERTIES, value: nil,
//                                             permissions: WR_PERMISSIONS)
//            serialService.characteristics = [writeCharacteristics]
//            peripheralManager.add(serialService)
//
//            peripheralManager.startAdvertising(beaconPeripheralData as? [String: Any])
//            let advertisementData = String(format: "%@", UIDevice.current.identifierForVendor!.uuidString)
//            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: BLE_UUID,
//                                                CBAdvertisementDataLocalNameKey: advertisementData])
//
            print("dadsfdnfkjdnsfjknadskfjndksjfadskfnkadshfds")
            
            transferCharacteristic = CBMutableCharacteristic(type: CBUUID(string: BLE_UUID), properties: .notify, value: nil, permissions: .readable)
        
            let transferService = CBMutableService(type: CBUUID(string: BLE_UUID), primary: true)
            
            transferService.characteristics = [transferCharacteristic!]
            
            peripheralManager.add(transferService)
            
        } else if peripheral.state == .poweredOff {
            print("afhsfhldfhlffjiodffkljhfkjhlkjaflkjsdhflkjsdhf")
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
    
    public func startSendReceivingBluetoothData() {
        print("initalizing function called")
        let bt_queue = DispatchQueue(label: "BT_queue")
//        centralManager = CBCentralManager(delegate: self, queue: nil)
//        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
//        centralManager.scanForPeripherals(withServices: [CBUUID(string: BLE_UUID)], options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
//
//        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [CBUUID(string: BLE_UUID)]])
        
//        sendData()
    }
    
    
    
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral!
    var data: NSMutableData!
    
    //MARK: BLE Central Code

    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("cbghaugbafjd;jfd;jfsdhfdshfklsdhfkhdslkfhsdkfhsdlkflksadhfkjads;")
        if (central.state == .poweredOn) {
            print("Scanining for Peripherals")
            scan()
          //here we scan for the devices with a UUID that is specific to our app, which filters out other BLE devices.
            
        } else {
            return
        }
    }
    
    func scan() {
        self.centralManager?.scanForPeripherals(withServices: [CBUUID(string: BLE_UUID)], options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)])
        print("Scanning has started")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("peripheral.identifier \(peripheral.identifier)")
        
        if RSSI.intValue > -15, RSSI.intValue < -35 {
            return
        }
        
        print("Discovered \(peripheral.name ?? "perihperal") at \(RSSI)")
        
        if discoveredPeripheral != peripheral {
            discoveredPeripheral = peripheral
            
            print("Connecting to peripheral \(peripheral)")
            
            centralManager.connect(peripheral, options: nil)
        }
    }

    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect with \(peripheral). (\(error?.localizedDescription ?? "error")")
        cleanup()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to Peripheral")
        
        centralManager.stopScan()
        
        data.length = 0
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: BLE_UUID)])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("Error discovering services \(error!.localizedDescription)")
            cleanup()
            return
        }
        
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([CBUUID(string: BLE_UUID)], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("Error discovering characteristics \(error!.localizedDescription)")
            cleanup()
            return
        }
        
        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid.isEqual(CBUUID(string: BLE_UUID)) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Error discovering characteristics \(error!.localizedDescription)")
            return
        }
        
        var stringFromData: String? = nil
        
        if let value = characteristic.value {
            stringFromData = String(data: value, encoding: .utf8)
        }
        
        if(stringFromData == "EOM") {
            
            print("Data \(data)")
            
            peripheral.setNotifyValue(false, for: characteristic)
            
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        if let value = characteristic.value {
            data.append(value)
        }
        
        print("Received Data: \(stringFromData ?? "")")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Error discovering characteristics \(error!.localizedDescription)")
        }
        
        if !characteristic.uuid.isEqual(CBUUID(string: BLE_UUID)) {
            return
        }
        
        if characteristic.isNotifying {
            print("Notification began on \(characteristic)")
        } else {
            print("Notification has stopped on \(characteristic).  DISCONNECTING")
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Peripheral Disconnected")
        discoveredPeripheral = nil
        
        scan()
    }
    
    func cleanup() {
        if discoveredPeripheral?.state != CBPeripheralState.connected {
            return
        }
        
        if discoveredPeripheral.services != nil {
            for service in discoveredPeripheral.services! {
                if service.characteristics != nil {
                    for characteristics in service.characteristics ?? [] {
                        if characteristics.uuid.isEqual(CBUUID(string: BLE_UUID)) {
                            if characteristics.isNotifying {
                                discoveredPeripheral.setNotifyValue(false , for: characteristics)
                                return
                            }
                        }
                    }
                }
            }
        }
        
        centralManager.cancelPeripheralConnection(discoveredPeripheral)
    }
    
    
    //MARK: BLE Peripheral Code
    
    
    private var transferCharacteristic: CBMutableCharacteristic?
    private var dataToSend: NSData? = UIDevice.current.identifierForVendor?.uuidString.data(using: .utf8) as NSData?
    private var sendDataIndex = 0
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Central subscribed to characteristic")
        
                
        sendDataIndex = 0
        
        sendData()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("Central unscribed from characteristic")
    }
    
    func sendData() {
        var sendingEOM = false
        
        if sendingEOM {
            var didSend: Bool? = nil
            if let data = "EOM".data(using: .utf8) {
                didSend = peripheralManager.updateValue(data, for: transferCharacteristic!, onSubscribedCentrals: nil)
            }
        
            if didSend ?? false {
                sendingEOM = false
                
                print("Sent: EOM")
            }
            
            return
        }
        
        if sendDataIndex >= dataToSend!.count {
            return
        }
        
        var didSend = true
        
        while didSend {
            var amountToSend = dataToSend!.count - sendDataIndex
            
            if amountToSend > 20 { //no bigger than 20 bytes
                amountToSend = 20
            }
            
            let chunk = Data(bytes: UnsafeRawPointer(dataToSend!.bytes + sendDataIndex), count: amountToSend)
            
            didSend = peripheralManager.updateValue(chunk, for: transferCharacteristic!, onSubscribedCentrals: nil)
            
            if !didSend {
                return
            }
            
            let stringFromData = String(data: chunk, encoding: .utf8)
            print("Sent: \(stringFromData ?? "")")
            
            sendDataIndex = amountToSend
            
            if sendDataIndex >= dataToSend!.count {
                sendingEOM = true
                let eomSent = peripheralManager.updateValue(data as Data, for: transferCharacteristic!, onSubscribedCentrals: nil)
                
                if eomSent {
                    sendingEOM = false
                    print("Sent EOM")
                }
                
                return
            }
    
            
        }
        
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        sendData()
    }
    
    
    init(centralManager: CBCentralManager, peripheralManager: CBPeripheralManager) {
        self.peripheralManager = peripheralManager
        self.centralManager = centralManager
    }
    

}

protocol BluetoothHandlerDelegate {
    func didUpdateProximityToUser(distance: CLProximity, uuid: String)
}
