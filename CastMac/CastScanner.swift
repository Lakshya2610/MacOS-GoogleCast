//
//  CastScanner.swift
//  CastMac
//
//  Created by Lakshya Gupta on 2022-08-28.
//

import Foundation
import OpenCastSwift

struct CastDeviceInstance : Identifiable
{
    let id: String
    let instance: CastDevice
}

class CastScanner
{
    private var m_scanner: CastDeviceScanner
    private var m_lastScanTime: Double
    private var m_discoveredDevices: [ CastDevice ]
    
    static let instance = CastScanner()
    
    // Notifications
    public static let DeviceListUpdated = Notification.Name(rawValue: "DiscoveredDevicesListUpdated")
    
    init()
    {
        m_scanner = CastDeviceScanner()
        m_discoveredDevices = []
        m_lastScanTime = NSDate().timeIntervalSince1970
    }
    
    public func ScanForCastDevices()
    {
        print("Scanning for cast compatible devices")
        
        NotificationCenter.default.addObserver(forName: CastDeviceScanner.deviceListDidChange, object: m_scanner, queue: nil) { _ in
            print("Scan finished")
            self.m_lastScanTime = NSDate().timeIntervalSince1970
            
            self.m_discoveredDevices.removeAll()
            let devices = self.m_scanner.devices
            print( "Found ", String(devices.count), " devices" )
            
            for i in 0..<devices.count
            {
                print("Device [" + String(i + 1) + "]: ", devices[i].name, " | ", devices[i].modelName, devices[i].ipAddress, ":", devices[i].port)
                
                self.m_discoveredDevices.append( devices[i] )
            }
            
            NotificationCenter.default.post(name: CastScanner.DeviceListUpdated, object: self)
        }

        m_scanner.startScanning()
    }
    
    public func GetDiscoveredDevices() -> [ CastDevice ]
    {
        return m_discoveredDevices
    }
    
    public func IsScanning() -> Bool
    {
        return m_scanner.isScanning;
    }
    
    public func StopScan()
    {
        m_scanner.stopScanning()
    }
    
    public func Reset()
    {
        m_discoveredDevices.removeAll()
        m_lastScanTime = 0
        m_scanner.reset()
    }
    
    public func GetTimeSinceLastScan() -> TimeInterval
    {
        let scantime = TimeInterval(m_lastScanTime)
        let time = NSDate(timeIntervalSince1970: scantime)
        return time.timeIntervalSinceNow
    }
}
