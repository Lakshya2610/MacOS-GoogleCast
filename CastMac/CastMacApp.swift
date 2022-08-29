//
//  CastMacApp.swift
//  CastMac
//
//  Created by Lakshya Gupta on 2022-08-28.
//

import SwiftUI
import OpenCastSwift

@main
struct CastMacApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView().frame(minWidth: 400, minHeight: 400)
        }
    }
}

public func ConnectToDevice(device: CastDevice)
{
    print("Attempting connection to device", device.name)
    if (Client != nil)
    {
        print("Starting a new connection when another may be active, stopping the old one")
        Client?.disconnect()
        Client?.stop()
    }
    
    Client = CastClient(device: device)
    Client?.delegate = CastClientEventHandler.instance
    Client?.connect()
}

public func DisconnectFromClient()
{
    print("Trying to disconnect from client")
    if (Client != nil)
    {
        print("Stopping connection with device", Client?.device.name ?? "<invalid device>")
        Client?.disconnect()
    }
}

public func TryLaunchMediaPlayer(media: CastMedia)
{
    if (Client == nil || !Client!.isConnected)
    {
        print("Tried to launch media player when no connection is active, ignoring")
        return
    }
    
    Client?.launch(appId: CastAppIdentifier.defaultMediaPlayer)
    { result in
        switch result
        {
            case .success(let app):
            Client?.load(media: media, with: app)
            { result in
                switch result
                {
                    case .success(let status):
                        print(status)
                        MonitorActiveMedia(app: app)

                    case .failure(let error):
                        print(error)
                }
            }
            case .failure(let err):
                print(err)
        }
    }
}

private func MonitorActiveMedia(app: CastApp)
{
    print("Starting app monitor for app", app.displayName)
    if (AppMonitor != nil)
    {
        AppMonitor?.Stop()
    }
    
    AppMonitor = CastAppMonitor(app: app, monitorInterval: APP_MONITOR_INTERVAL_S)
}
