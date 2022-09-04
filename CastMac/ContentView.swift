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

//        not ideal, but easy for quick (& laggy) preview of the screen capture
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
        Button("Refresh Displays", action: SCMgr.RefreshSharableContent)
        Button("Screen Share", action: ScreenShare)
        Button("Stop Screen Share", action: StopScreenShare)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
