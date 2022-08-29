//
//  ScreenSharing.swift
//  CastMac
//
//  Created by Lakshya Gupta on 2022-08-29.
//

import Foundation
import ScreenCaptureKit

private let printlabel = "[ScreenSharing]:"

struct CapturedFrame
{
    let surface: IOSurface
    let rect: CGRect
    let scale: CGFloat
    let factor: CGFloat
}

class SCMgr
{
    static var SharableDisplays: [ SCDisplay ] = []
    static var SharableWindows: [ SCWindow ] = []
    static var SharableApps: [ SCRunningApplication ] = []
    
    static var StreamConfig: SCStreamConfiguration = SCStreamConfiguration()
    static var Stream: SCStream? = nil
    static let ScreenShareOuputReciever = SCOutputHandler()
    
    static func RefreshSharableContent()
    {
        print(printlabel, "refreshing list of availible windows/displays")
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true)
        { sharableContent, err in
            print(printlabel, "Found", sharableContent?.displays.count ?? "0", "sharable displays")
            print(printlabel, "Found", sharableContent?.windows.count ?? "0", "sharable windows")
            print(printlabel, "Found", sharableContent?.applications.count ?? "0", "sharable apps")
            
            SCMgr.SharableDisplays.removeAll()
            SCMgr.SharableWindows.removeAll()
            SCMgr.SharableApps.removeAll()
            
            SCMgr.SharableDisplays.append(contentsOf: sharableContent?.displays ?? [])
            SCMgr.SharableWindows.append(contentsOf: sharableContent?.windows ?? [])
            SCMgr.SharableApps.append(contentsOf: sharableContent?.applications ?? [])
        }
    }
}

class SCOutputHandler : NSObject, SCStreamOutput
{
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        
        print("here")
        
        guard sampleBuffer.isValid else { return }
        
        // Determine which type of data the sample buffer contains.
        switch type {
        case .screen:
           let _ = ProcessVideoBuffer(buffer: sampleBuffer)
        @unknown default:
            return
        }
    }
    
    func ProcessVideoBuffer(buffer: CMSampleBuffer) -> CapturedFrame?
    {
        // Retrieve the array of metadata attachments from the sample buffer.
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentsArray.first else { return nil }
        
        // Validate the status of the frame. If it isn't `.complete`, return nil.
        guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
              let status = SCFrameStatus(rawValue: statusRawValue),
              status == .complete else { return nil }
        
        guard let pixelBuffer = buffer.imageBuffer else { return nil }
        // Get the backing IOSurface.
        guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else { return nil }
        let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)
        
        // Retrieve the content rectangle, scale, and scale factor.
        guard let contentRectDict = attachments[.contentRect],
              let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary),
              let contentScale = attachments[.contentScale] as? CGFloat,
              let scaleFactor = attachments[.scaleFactor] as? CGFloat else { return nil }
        
        let frame = CapturedFrame(surface: surface,
                                  rect: contentRect,
                                  scale: contentScale,
                                  factor: scaleFactor)
        
        return frame
    }
}

class ScreenShareStreamEventsHandler : NSObject, SCStreamDelegate
{
    static let instance = ScreenShareStreamEventsHandler()
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print(printlabel, "Stream stopped with error -", error)
    }
}

public func ScreenShare()
{
    let window = SCMgr.SharableWindows.first(where: { win in
        return win.title == "Desktop"
    })
    
    if (window == nil)
    {
        print("No desktop window found, stopping screen capture")
        return
    }
    
    SCMgr.StreamConfig.showsCursor = true
    SCMgr.StreamConfig.width = Int(window!.frame.width) * 2
    SCMgr.StreamConfig.height = Int(window!.frame.height) * 2
    SCMgr.StreamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 60)
    SCMgr.StreamConfig.queueDepth = 3
    
    // Note: SCContentFilter/SCStream is bugged, it doesn't work when there are 0 excludingApplications & 0 exceptingWindows
    let excludedApps = SCMgr.SharableApps.filter { app in
        Bundle.main.bundleIdentifier == app.bundleIdentifier
    }
    
    let filter = SCContentFilter(display: SCMgr.SharableDisplays[0], excludingApplications: excludedApps, exceptingWindows: [])
    let stream = SCStream(filter: filter, configuration: SCMgr.StreamConfig, delegate: ScreenShareStreamEventsHandler.instance)
    SCMgr.Stream = stream
    
    try! stream.addStreamOutput(SCMgr.ScreenShareOuputReciever, type: SCStreamOutputType.screen, sampleHandlerQueue: nil)
    
    stream.startCapture(completionHandler: { error in
        if ( error != nil )
        {
            print(printlabel, "Failed to start capture -", error ?? "")
        }
        else
        {
            print(printlabel, "Started screen capture")
        }
    })
}

public func StopScreenShare()
{
    SCMgr.Stream?.stopCapture(completionHandler: {
        err in
        if (err != nil)
        {
            print(printlabel, "Failed to stop screen capture -", err ?? "")
        }
        else
        {
            print(printlabel, "Screen capture stopped")
        }
    })
}
