//
//  ContentView.swift
//  CastMac
//
//  Created by Lakshya Gupta on 2022-08-28.
//

import SwiftUI
import OpenCastSwift

struct ContentView: View {
    
    let devicelistWatch = NotificationCenter.default.publisher(for: CastScanner.DeviceListUpdated)
    
    @State var devicelist: [ CastDeviceInstance ] = []
    
    private func UpdateDeviceList()
    {
        let discoveredDevices = CastScanner.instance.GetDiscoveredDevices()
        
        devicelist.removeAll()
        for device in discoveredDevices {
            devicelist.append(CastDeviceInstance(id: device.id, instance: device))
        }
    }
    
    var body: some View {
        List
        {
            ForEach(devicelist) { device in
                Button(device.instance.name, action: {
                    ConnectToDevice(device: device.instance)
                })
            }
        }.onReceive(devicelistWatch) { (output) in
            UpdateDeviceList()
        }.padding()
        
        ScanButton()
        Button("Disconnect", action: DisconnectFromClient)
        Button("Media Player", action: { TryLaunchMediaPlayer(media: media) })
    }
}

let videoURL = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!
let posterURL = URL(string: "https://i.imgur.com/GPgh0AN.jpg")!

// create a CastMedia object to hold media information
let media = CastMedia(title: "Test media",
                        url: videoURL,
                        poster: posterURL,
                        contentType: "video/mp4",
                        streamType: CastMediaStreamType.buffered,
                        autoplay: true,
                        currentTime: 0)

struct ScanButton : View
{
    var body: some View
    {
        Button("Scan", action: CastScanner.instance.ScanForCastDevices).padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
