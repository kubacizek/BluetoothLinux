//
//  DevicePollEvent.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/27/18.
//

import Foundation
import Bluetooth
import BluetoothHCI
import SystemPackage

@available(macOS 12.0, *)
public extension HostController {
    
    /// Polls and waits for events.
    func poll<Event>(
        for event: Event.Type
    ) -> AsyncThrowingStream<Event, Swift.Error> where Event: HCIEventParameter, Event.HCIEventType == HCIGeneralEvent {
        return fileDescriptor.poll(for: Event.self)
    }
}

public extension HostController {
    
    @available(*, deprecated)
    func pollEvent<EP>(_ eventParameterType: EP.Type, shouldContinue: () -> (Bool), event: (EP) throws -> ()) throws where EP : HCIEventParameter {
        fatalError()
    }
}

@available(macOS 12.0, *)
internal extension FileDescriptor {
    
    func poll<Event>(
        for event: Event.Type
    ) -> AsyncThrowingStream<Event, Error> where Event: HCIEventParameter, Event.HCIEventType == HCIGeneralEvent {
        return AsyncThrowingStream(Event.self, bufferingPolicy: .unbounded) { continuation in
            Task {
                var newFilter = HCISocketOption.Filter()
                newFilter.setPacketType(.event)
                newFilter.setEvent(Event.event)
                do {
                    try await setFilter(newFilter) {
                        var eventBuffer = [UInt8](repeating: 0, count: HCIEventHeader.maximumSize)
                        // keep on reading until cancelled
                        while Task.isCancelled == false {
                            let bytesRead = try await read(into: &eventBuffer)
                            let eventData = Data(eventBuffer[(1 + HCIEventHeader.length) ..< bytesRead]) // create unsafe data pointer
                            guard let eventParameter = Event.init(data: eventData)
                                else { throw BluetoothHostControllerError.garbageResponse(eventData) }
                            continuation.yield(eventParameter)
                        }
                    }
                }
                catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
