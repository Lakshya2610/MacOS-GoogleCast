//
//  ContentView.swift
//  CastMac
//
//  Created by Lakshya Gupta on 2022-08-28.
//

import SwiftUI
import OpenCastSwift

struct ContentView: View {
    
    let devicelistUpdated = NotificationCenter.default.publisher(for: CastScanner.DeviceListUpdated)
    let newFrameReady = NotificationCenter.default.publisher(for: NextFrameReady).receive(on: RunLoop.main)
    
    @State var devicelist: [ CastDeviceInstance ] = []
    @State var screenCaptureFrame: Image = Image("nyc")
    
    private func UpdateDeviceList()
    {
        let discoveredDevices = CastScanner.instance.GetDiscoveredDevices()
        
        devicelist.removeAll()
        for device in discoveredDevices {
            devicelist.append(CastDeviceInstance(id: device.id, instance: device))
        }
    }
    
    private func OnNewSCFrame()
    {
        if (lastFrame == nil)
        {
            return
        }
        
        let nsImgRep = NSCIImageRep(ciImage: lastFrame!)
        let nsImg = NSImage(size: nsImgRep.size)
        nsImg.addRepresentation(nsImgRep)
        screenCaptureFrame = Image(nsImage: nsImg)
    }
    
    var body: some View {
        List
        {
            ForEach(devicelist) { device in
                Button(device.instance.name, action: {
                    ConnectToDevice(device: device.instance)
                })
            }
        }.onReceive(devicelistUpdated) { (output) in
            UpdateDeviceList()
        }.padding()
        
//        screenCaptureFrame.resizable().scaledToFit().onReceive(newFrameReady) { _ in
//            OnNewSCFrame()
//        }
        
        HStack(content: {
            CastButtons()
        })
        
        Spacer()
        
        HStack(alignment: VerticalAlignment.center, spacing: 10.0, content: {
            ScreenShareButtons()
        })
    }
}

let videoURL = URL(string: "http://192.168.1.44:8080/out.m3u8")!
//let videoURL = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!
let posterURL = URL(string: "https://i.imgur.com/GPgh0AN.jpg")!

// create a CastMedia object to hold media information
let media = CastMedia(title: "Test media",
                        url: videoURL,
                        poster: posterURL,
                        contentType: "application/x-mpegurl",
                        streamType: CastMediaStreamType.live,
                        autoplay: true,
                        currentTime: 0)

struct CastButtons : View
{
    var body: some View
    {
        Button("Scan", action: CastScanner.instance.ScanForCastDevices)
        Button("Disconnect", action: DisconnectFromClient)
        Button("Media Player", action: { TryLaunchMediaPlayer(media: media) })
    }
}

struct ScreenShareButtons : View
{
    var body: some View
    {
        Button("Refresh Displays", action: {
            SCMgr.RefreshSharableContent()
        })
        Button("Screen Share", action: ScreenShare)
        Button("Stop Screen Share", action: StopScreenShare)
        Button("Connect Relay", action: UploadClient.instance.ConnectToRelay)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
