//
//  CastConnection.swift
//  CastMac
//
//  Created by Lakshya Gupta on 2022-08-29.
//

import Foundation
import OpenCastSwift

class CastClientEventHandler : CastClientDelegate
{
    static let instance = CastClientEventHandler()
    
    func castClient(_ client: CastClient, willConnectTo device: CastDevice) {
        print("Preparing to connect to", device.name)
    }
    
    func castClient(_ client: CastClient, connectionTo device: CastDevice, didFailWith error: Error?) {
        print("Connection to device", device.name, "failed")
        
        print(error?.localizedDescription ?? "")
    }
    
    func castClient(_ client: CastClient, didConnectTo device: CastDevice) {
        print("Successfully connected to device", device.name)
    }
    
    func castClient(_ client: CastClient, didDisconnectFrom device: CastDevice) {
        print("Disconnected from device", device.name)
    }
}

final class CastAppMonitor
{
    let app: CastApp
    private let monitorTimer: Timer?
    
    init(app: CastApp, monitorInterval: UInt8) {
        self.app = app
        if (monitorInterval > 0)
        {
            let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(monitorInterval), repeats: true)
            { _ in
                CastAppMonitor.CheckStatus(app: app)
            }
            
            self.monitorTimer = timer
        }
        else
        {
            self.monitorTimer = nil
        }
    }
    
    deinit {
        if (self.monitorTimer != nil && self.monitorTimer!.isValid)
        {
            self.monitorTimer?.invalidate()
        }
    }
    
    static func CheckStatus(app: CastApp)
    {
        if (Client == nil)
        {
            return
        }
        
        Client?.requestMediaStatus(for: app) // TODO: this doesn't work, fix it
        { result in
            switch result {
              case .success(let status):
                print("[APP_STATE]:", status)

              case .failure(let error):
                print("[APP_STATE]:", error)
            }
        }
    }
    
    public func Stop()
    {
        self.monitorTimer?.invalidate()
    }
}
