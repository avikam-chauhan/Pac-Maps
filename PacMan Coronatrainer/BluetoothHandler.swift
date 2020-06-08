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
    
    
    //MARK: Send UUID over Bluetooth
    
    public func startSendReceivingBluetoothData() {
        print("Initializing function called")
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
    }
    
    //MARK: BLE Central Code
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn) {
            print("Scanining for Peripherals")
            scan()
            //Here we scan for the devices with a UUID that is specific to our app, which filters out other BLE devices.
        } else {
            return
        }
    }
    
    func scan() {
        self.centralManager?.scanForPeripherals(withServices: [CBUUID(string: BLE_UUID)], options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)])
        print("Scanning has started")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        print("peripheral.identifier \(peripheral.identifier)")
        
        if RSSI.intValue > -15, RSSI.intValue < -35 {
            return
        }
        
//        print("Discovered \(peripheral.name ?? "perihperal") at \(RSSI)")
        
        //MARK: Connection with Peripheral
        
        //        var historyOfConnectedPeripheralIdentifiers: [String] = getHistoryOfDiscoveredPeripheralIdentifiers()
        
        //loop through
        
        //            if discoveredPeripheral != peripheral {
        discoveredPeripheral = peripheral
        
//        print("Connecting to peripheral \(peripheral)")
        
        centralManager.connect(peripheral, options: nil)
        //            }
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
            
            print("Data \(data ?? NSMutableData())")
            
            peripheral.setNotifyValue(false, for: characteristic)
            
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        if let value = characteristic.value {
            data.append(value)
        }
        
        print("Received Data: \(stringFromData ?? "")")
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Error discovering characteristics \(error!.localizedDescription)")
        }
        
        if !characteristic.uuid.isEqual(CBUUID(string: BLE_UUID)) {
            return
        }
        
        if characteristic.isNotifying {
//            print("Notification began on \(characteristic)")
        } else {
//            print("Notification has stopped on \(characteristic).  DISCONNECTING")
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
//        print("Central subscribed to characteristic")
        
        sendDataIndex = 0
        
        sendData()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
//        print("Central unscribed from characteristic")
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
                
                print("Sent: EOM")
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
            print("Sent: \(stringFromData ?? "")")
            
            sendDataIndex += amountToSend
            
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
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("Peripheral Services Changed")
    }
}
