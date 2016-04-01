//
//  GATTServerTest.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/13/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import BluetoothLinux
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

func GATTServerTest(adapter: Adapter) {
    
    let uuid = { BluetoothUUID.Bit128(UUID()) }
    
    let characteristic = GATTDatabase.Characteristic(UUID: uuid(), value: "Hey".toUTF8Data().byteValue, permissions: [.Read, .Write], properties: [.Read, .Write])
    
    let characteristic2 = GATTDatabase.Characteristic(UUID: uuid(), value: "Hola".toUTF8Data().byteValue, permissions: [.Read, .Write], properties: [.Read, .Write])
    
    let database = GATTDatabase(services: [GATTDatabase.Service(characteristics: [characteristic, characteristic2], UUID: uuid())])
    
    print("GATT Database:")
    
    for attribute in database.attributes {
        
        let typeText: String
        
        if let gatt = GATT.UUID(UUID: attribute.UUID) {
            
            typeText = "\(gatt)"
            
        } else {
            
            typeText = "\(attribute.UUID)"
        }
        
        print("\(attribute.handle) - \(typeText)")
        print("Permissions: \(attribute.permissions)")
        print("Value: \(attribute.value)")
    }
    
    do {
        
        let address = adapter.address!
        
        let serverSocket = try L2CAPSocket(adapterAddress: address, channelIdentifier: ATT.CID, addressType: .LowEnergyPublic, securityLevel: .Low)
        
        print("Created L2CAP server")
        
        let newSocket = try serverSocket.waitForConnection()
        
        print("New \(newSocket.addressType) connection from \(newSocket.address)")
        
        let server = GATTServer(socket: newSocket)
        
        server.log = { print("[\(newSocket.address)]: " + $0) }
        
        server.database = database
        
        while true {
            
            try server.read()
            
            try server.write()
        }
    }
        
    catch { Error("Error: \(error)") }
}