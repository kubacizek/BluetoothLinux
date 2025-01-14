//
//  DeviceRequest.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import Foundation
import Bluetooth
import BluetoothHCI

public extension HostController {

    /// Send an HCI command with parameters to the controller and waits for a response.
    func deviceRequest<CP: HCICommandParameter, EP: HCIEventParameter> (
        _ commandParameter: CP,
        _ eventParameterType: EP.Type,
        timeout: HCICommandTimeout = .default
    ) throws -> EP {
            
        let command = CP.command
        let parameterData = commandParameter.data
        let responseData = try fileDescriptor.sendRequest(
            command: command,
            commandParameterData: parameterData,
            event: EP.event.rawValue,
            eventParameterLength: EP.length,
            timeout: timeout
        )
        guard let eventParameter = EP(data: responseData)
            else { throw BluetoothHostControllerError.garbageResponse(responseData) }
        
        return eventParameter
    }
    
    /// Send an HCI command to the controller and waits for a response.
    func deviceRequest<C, EP>(
        _ command: C,
        _ eventParameterType: EP.Type,
        timeout: HCICommandTimeout = .default
    ) throws -> EP where C : HCICommand, EP : HCIEventParameter {
        
        let data = try fileDescriptor.sendRequest(
            command: command,
            event: EP.event.rawValue,
            eventParameterLength: EP.length,
            timeout: timeout
        )
        
        guard let eventParameter = EP(data: data)
            else { throw BluetoothHostControllerError.garbageResponse(data) }
        
        return eventParameter
    }
    
    /*
    @inline(__always)
    func deviceRequest<C: HCICommand, EP: HCIEventParameter>(command: C, eventParameterType: EP.Type, timeout: HCICommandTimeout = .default) throws -> EP {

        let opcode = (command.rawValue, C.opcodeGroupField.rawValue)

        let event = EP.event.rawValue

        let data = try HCISendRequest(internalSocket, opcode: opcode, event: event, eventParameterLength: EP.length, timeout: timeout)

        guard let eventParameter = EP(bytes: data)
            else { throw BluetoothHostControllerError.GarbageResponse(Data(bytes: data)) }

        return eventParameter
    }

    @inline(__always)
    func deviceRequest<CP: HCICommandParameter, E: HCIEvent>(commandParameter: CP, event: E, verifyStatusByte: Bool = true, timeout: HCICommandTimeout = .default) throws {

        let command = CP.command

        let opcode = (command.rawValue, command.dynamicType.opcodeGroupField.rawValue)

        let parameterData = commandParameter.bytes

        let eventParameterLength = verifyStatusByte ? 1 : 0

        let data = try HCISendRequest(internalSocket, opcode: opcode, commandParameterData: parameterData, event: event.rawValue, eventParameterLength: eventParameterLength, timeout: timeout)

        if verifyStatusByte {

            guard let statusByte = data.first
                else { fatalError("Missing status byte!") }

            guard statusByte == 0x00
                else { throw BluetoothHostControllerError.DeviceRequestStatus(statusByte) }
        }
    }

    @inline(__always)
    func deviceRequest<C: HCICommand, E: HCIEvent>(command: C, event: E, verifyStatusByte: Bool = true, timeout: HCICommandTimeout = .default) throws {

        let opcode = (command.rawValue, C.opcodeGroupField.rawValue)

        let eventParameterLength = verifyStatusByte ? 1 : 0

        let data = try HCISendRequest(internalSocket, opcode: opcode, event: event.rawValue, eventParameterLength: eventParameterLength, timeout: timeout)

        if verifyStatusByte {

            guard let statusByte = data.first
                else { fatalError("Missing status byte!") }

            guard statusByte == 0x00
                else { throw BluetoothHostControllerError.DeviceRequestStatus(statusByte) }
        }
    }
 
    */
    
    /// Send a command to the controller and wait for response. 
    func deviceRequest<C: HCICommand>(
        _ command: C,
        timeout: HCICommandTimeout = .default
    ) throws {

        let data = try fileDescriptor.sendRequest(
            command: command,
            eventParameterLength: 1,
            timeout: timeout
        )
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
        
    }
    
    func deviceRequest<CP: HCICommandParameter>(
        _ commandParameter: CP,
        timeout: HCICommandTimeout = .default
    ) throws {
        
        let data = try fileDescriptor.sendRequest(
            command: CP.command,
            commandParameterData: commandParameter.data,
            eventParameterLength: 1,
            timeout: timeout
        )
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
    }
    
    func deviceRequest <Return: HCICommandReturnParameter> (
        _ commandReturnType : Return.Type,
        timeout: HCICommandTimeout = .default
    ) throws -> Return {
        
        let data = try fileDescriptor.sendRequest(
            command: commandReturnType.command,
            eventParameterLength: commandReturnType.length + 1, // status code + parameters
            timeout: timeout
        )
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
        
        guard let response = Return(data: Data(data.suffix(from: 1)))
            else { throw BluetoothHostControllerError.garbageResponse(Data(data)) }
        
        return response
    }
    
    /// Sends a command to the device and waits for a response with return parameter values.
    func deviceRequest <CP: HCICommandParameter, Return: HCICommandReturnParameter> (
        _ commandParameter: CP,
        _ commandReturnType : Return.Type,
        timeout: HCICommandTimeout = .default
    ) throws -> Return {
        
        assert(CP.command.opcode == Return.command.opcode)
        
        let data = try fileDescriptor.sendRequest(
            command: commandReturnType.command,
            commandParameterData: commandParameter.data,
            eventParameterLength: commandReturnType.length + 1,
            timeout: timeout
        )
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
        
        guard let response = Return(data: Data(data.suffix(from: 1)))
            else { throw BluetoothHostControllerError.garbageResponse(Data(data)) }
        
        return response
    }
}
