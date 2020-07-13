////
////  BluetoothHandler.swift
////  PacMan Coronatrainer
////
////  Created by Mihir Chauhan on 5/27/20.
////  Copyright © 2020 Avikam Chauhan. All rights reserved.
////
//
//  BluetoothHandler.swift
//  BLEDataTransfer
//
//  Created by Mihir Chauhan on 6/5/20.
//  Copyright © 2020 Mihir Chauhan. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation
import UIKit

class BluetoothHandler: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate {
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral!
    var data: NSMutableData! = NSMutableData()
    let BLE_UUID = "5DE63112-432E-4D11-AFDF-F6F091689061"
    var peripheralManager: CBPeripheralManager!
    var bluetoothHandlerDelegate: BluetoothHandlerDelegate?
    var timeSinceContact: Date? = nil
    var timeInContact: Double!
    var contactedPlayerUUID: UUID? = nil
    
    var isLookingForFamilyMember = false
    
    public func lookForFamilyMember(isLooking: Bool) {
        isLookingForFamilyMember = isLooking
    }
    
        
    //MARK: Send UUID over Bluetooth
    
    var currentTime: Double!
    
    public func startSendReceivingBluetoothData() {
        currentTime = NSDate().timeIntervalSince1970 * 1000
        //print("BLE:    Initializing function called")
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    //MARK: BLE Central Code
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn) {
            //print("BLE:    Scanining for Peripherals")
            scan()
            //Here we scan for the devices with a UUID that is specific to our app, which filters out other BLE devices.
            bluetoothHandlerDelegate?.didUpdateBluetooth(distance: CLProximity.unknown)
        } else {
            return
        }
    }
    
    func scan() {
        self.centralManager?.scanForPeripherals(withServices: [CBUUID(string: BLE_UUID)], options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)])
        //print("BLE:    Scanning has started")
    }
    
    var runningArrayOfRSSI: [Double] = []
    var counter: Int = 0
//    var canRemoveFromAllContactedUsers: Int = 0
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if contactedPlayerUUID != nil {
            FirebaseInterface.checkIfIsAFamilyMember(withUUID: contactedPlayerUUID)
            if FirebaseInterface.isAFamilyMember {
                bluetoothHandlerDelegate?.didUpdateBluetooth(distance: CLProximity.unknown)
//                if canRemoveFromAllContactedUsers < 2 {
                    FirebaseInterface.removeAllInstancesOfAllContactedUsers(yourUUID: UIDevice.current.identifierForVendor!, familyMemberUUID: contactedPlayerUUID)
//                    canRemoveFromAllContactedUsers += 1
//                }
            } else {
//                canRemoveFromAllContactedUsers = 0
                if(currentTime + 2000 <= NSDate().timeIntervalSince1970 * 1000) {
                    currentTime = NSDate().timeIntervalSince1970 * 1000
                    var averageRSSI: Double = 0
                    for signalStrenths in 0..<runningArrayOfRSSI.count {
                        averageRSSI += runningArrayOfRSSI[signalStrenths]
                    }
                    let distanceReading: Double = averageRSSI/Double(runningArrayOfRSSI.count)
                    runningArrayOfRSSI.removeAll()
                    if distanceReading < -80 {
                        //less than -80
                        bluetoothHandlerDelegate?.didUpdateBluetooth(distance: CLProximity.far)
                    } else if distanceReading > -50 {
                        //more than -50
                        bluetoothHandlerDelegate?.didUpdateBluetooth(distance: CLProximity.immediate)
                    } else if distanceReading <= -50 && distanceReading >= -80 {
                        //in between
                        bluetoothHandlerDelegate?.didUpdateBluetooth(distance: CLProximity.near)
                    } else {
                        //none
                        bluetoothHandlerDelegate?.didUpdateBluetooth(distance: CLProximity.unknown)
                    }
                } else {
                    runningArrayOfRSSI.append(RSSI.doubleValue)
                }
                timeInContact = Date().distance(to: timeSinceContact!)
                bluetoothHandlerDelegate?.didUpdateBluetooth(timeInContact: abs(Int(timeInContact)))
            }
        }
        
        
        
        if RSSI.intValue > -15, RSSI.intValue < -35 {
            return
        }
                
        //MARK: Connection with Peripheral
        
        if discoveredPeripheral != peripheral {
            discoveredPeripheral = peripheral
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func rssiToFeet(rssi: Double) -> Double {
        return pow(10, ((-56-Double(rssi))/(10*2)))*3.2808
        
        
        
//        let txPower: Double = -59
//        if(rssi == 0) {
//            return -1
//        }
//
//        let ratio = Double(rssi)*1.0/txPower
//        if(ratio < 1.0) {
//            return pow(ratio, 10)
//        } else {
//            let distance = (0.89976)*pow(ratio, 7.7095) + 0.111
//            return distance
//        }
//
//        if (rssi == 0) {
//          return -1.0 // if we cannot determine accuracy, return -1.
//        }
//
//        let ratio = Double(rssi)*1.0/txPower;
//        if (ratio < 1.0) {
//          return pow(ratio,10);
//        }
//        else {
//          let accuracy =  (0.89976)*pow(ratio,7.7095) + 0.111;
//          return accuracy;
//        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        //print("BLE:    Failed to connect with \(peripheral). (\(error?.localizedDescription ?? "error")")
        cleanup()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //print("BLE:    Connected to Peripheral")
        data.length = 0
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: BLE_UUID)])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            //print("BLE:    Error discovering services \(error!.localizedDescription)")
            cleanup()
            return
        }
        
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([CBUUID(string: BLE_UUID)], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            //print("BLE:    Error discovering characteristics \(error!.localizedDescription)")
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
            //print("BLE:    Error discovering characteristics \(error!.localizedDescription)")
            return
        }
        
        var stringFromData: String? = nil
        
        if let value = characteristic.value {
            stringFromData = String(data: value, encoding: .utf8)
        }
        
        if(stringFromData == "EOM") {
            
            //print("BLE:    Data \(data ?? NSMutableData())")
            
            peripheral.setNotifyValue(false, for: characteristic)
            
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        if let value = characteristic.value {
            data.append(value)
        }
        
        //print("BLE:    Received Data: \(stringFromData ?? "")")
        timeSinceContact = Date()
        bluetoothHandlerDelegate?.didUpdateBluetooth(otherUserUUID: stringFromData ?? "")
        contactedPlayerUUID = UUID(uuidString: stringFromData ?? "")
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            //print("BLE:    Error discovering characteristics \(error!.localizedDescription)")
        }
        
        if !characteristic.uuid.isEqual(CBUUID(string: BLE_UUID)) {
            return
        }
        
        if characteristic.isNotifying {
            //            //print("Notification began on \(characteristic)")
        } else {
            //            //print("Notification has stopped on \(characteristic).  DISCONNECTING")
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        //print("BLE:    Peripheral Disconnected")
        bluetoothHandlerDelegate?.didUpdateBluetooth(distance: CLProximity.unknown)
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
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            transferCharacteristic = CBMutableCharacteristic(type: CBUUID(string: BLE_UUID), properties: .notify, value: nil, permissions: .readable)
            
            let transferService = CBMutableService(type: CBUUID(string: BLE_UUID), primary: true)
            
            transferService.characteristics = [transferCharacteristic!]
            
            peripheralManager.add(transferService)
            
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [CBUUID(string: BLE_UUID)]])
        } else if peripheral.state == .poweredOff {
            peripheralManager.stopAdvertising()
        }
    }
    
    
    
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        //print("BLE:    Central subscribed to characteristic")
        
        sendDataIndex = 0
        
        sendData()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        //        //print("Central unscribed from characteristic")
    }
    
    func sendData() {
        //MARK: Sending Data
        var sendingEOM = false
        
        if sendingEOM {
            var didSend: Bool? = nil
            if let data = "EOM".data(using: .utf8) {
                didSend = peripheralManager.updateValue(data, for: transferCharacteristic!, onSubscribedCentrals: nil)
            }
            
            if didSend ?? false {
                sendingEOM = false
                
                //print("BLE:    Sent: EOM")
            }
            
            return
        }
        
        if sendDataIndex >= dataToSend!.count {
            return
        }
        
        var didSend = true
        
        while didSend {
            let amountToSend = dataToSend!.count - sendDataIndex
            
            let chunk = Data(bytes: UnsafeRawPointer(dataToSend!.bytes + sendDataIndex), count: amountToSend)
            
            didSend = peripheralManager.updateValue(chunk, for: transferCharacteristic!, onSubscribedCentrals: nil)
            
            if !didSend {
                return
            }
            
            let stringFromData = String(data: chunk, encoding: .utf8)
            //print("BLE:    Sent: \(stringFromData ?? "")")
            
            sendDataIndex += amountToSend
            
            if sendDataIndex >= dataToSend!.count {
                sendingEOM = true
                let eomSent = peripheralManager.updateValue(data as Data, for: transferCharacteristic!, onSubscribedCentrals: nil)
                
                if eomSent {
                    sendingEOM = false
                    //print("BLE:    Sent EOM")
                }
                
                return
            }
            
            
        }
        
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        sendData()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        //print("BLE:    Peripheral Services Changed")
        bluetoothHandlerDelegate?.didUpdateBluetooth(distance: CLProximity.unknown)
        if timeSinceContact != nil {
            contactedPlayerUUID = nil
//            timeInContact = Date().distance(to: timeSinceContact!)
//            bluetoothHandlerDelegate?.didUpdateBluetooth(timeInContact: abs(Int(timeInContact)))
        }

    }
}

protocol BluetoothHandlerDelegate {
    func didUpdateBluetooth(distance: CLProximity)
    func didUpdateBluetooth(otherUserUUID: String)
    func didUpdateBluetooth(timeInContact: Int)
}
