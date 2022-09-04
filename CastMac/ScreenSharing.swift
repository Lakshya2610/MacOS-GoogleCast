//
//  ScreenSharing.swift
//  CastMac
//
//  Created by Lakshya Gupta on 2022-08-29.
//

import Foundation
import ScreenCaptureKit

public let NextFrameReady = Notification.Name(rawValue: "SCNextFrameReady")
public var lastFrame: CIImage? = nil
private let printlabel = "[ScreenSharing]:"

struct CapturedFrame
{
    let bytes: Data
    let width: Int
    let height: Int
}

public func CVPixelBufferGetPixelFormatName(pixelBuffer: CVPixelBuffer) -> String {
    let p = CVPixelBufferGetPixelFormatType(pixelBuffer)
    switch p {
    case kCVPixelFormatType_1Monochrome:                   return "kCVPixelFormatType_1Monochrome"
    case kCVPixelFormatType_2Indexed:                      return "kCVPixelFormatType_2Indexed"
    case kCVPixelFormatType_4Indexed:                      return "kCVPixelFormatType_4Indexed"
    case kCVPixelFormatType_8Indexed:                      return "kCVPixelFormatType_8Indexed"
    case kCVPixelFormatType_1IndexedGray_WhiteIsZero:      return "kCVPixelFormatType_1IndexedGray_WhiteIsZero"
    case kCVPixelFormatType_2IndexedGray_WhiteIsZero:      return "kCVPixelFormatType_2IndexedGray_WhiteIsZero"
    case kCVPixelFormatType_4IndexedGray_WhiteIsZero:      return "kCVPixelFormatType_4IndexedGray_WhiteIsZero"
    case kCVPixelFormatType_8IndexedGray_WhiteIsZero:      return "kCVPixelFormatType_8IndexedGray_WhiteIsZero"
    case kCVPixelFormatType_16BE555:                       return "kCVPixelFormatType_16BE555"
    case kCVPixelFormatType_16LE555:                       return "kCVPixelFormatType_16LE555"
    case kCVPixelFormatType_16LE5551:                      return "kCVPixelFormatType_16LE5551"
    case kCVPixelFormatType_16BE565:                       return "kCVPixelFormatType_16BE565"
    case kCVPixelFormatType_16LE565:                       return "kCVPixelFormatType_16LE565"
    case kCVPixelFormatType_24RGB:                         return "kCVPixelFormatType_24RGB"
    case kCVPixelFormatType_24BGR:                         return "kCVPixelFormatType_24BGR"
    case kCVPixelFormatType_32ARGB:                        return "kCVPixelFormatType_32ARGB"
    case kCVPixelFormatType_32BGRA:                        return "kCVPixelFormatType_32BGRA"
    case kCVPixelFormatType_32ABGR:                        return "kCVPixelFormatType_32ABGR"
    case kCVPixelFormatType_32RGBA:                        return "kCVPixelFormatType_32RGBA"
    case kCVPixelFormatType_64ARGB:                        return "kCVPixelFormatType_64ARGB"
    case kCVPixelFormatType_48RGB:                         return "kCVPixelFormatType_48RGB"
    case kCVPixelFormatType_32AlphaGray:                   return "kCVPixelFormatType_32AlphaGray"
    case kCVPixelFormatType_16Gray:                        return "kCVPixelFormatType_16Gray"
    case kCVPixelFormatType_30RGB:                         return "kCVPixelFormatType_30RGB"
    case kCVPixelFormatType_422YpCbCr8:                    return "kCVPixelFormatType_422YpCbCr8"
    case kCVPixelFormatType_4444YpCbCrA8:                  return "kCVPixelFormatType_4444YpCbCrA8"
    case kCVPixelFormatType_4444YpCbCrA8R:                 return "kCVPixelFormatType_4444YpCbCrA8R"
    case kCVPixelFormatType_4444AYpCbCr8:                  return "kCVPixelFormatType_4444AYpCbCr8"
    case kCVPixelFormatType_4444AYpCbCr16:                 return "kCVPixelFormatType_4444AYpCbCr16"
    case kCVPixelFormatType_444YpCbCr8:                    return "kCVPixelFormatType_444YpCbCr8"
    case kCVPixelFormatType_422YpCbCr16:                   return "kCVPixelFormatType_422YpCbCr16"
    case kCVPixelFormatType_422YpCbCr10:                   return "kCVPixelFormatType_422YpCbCr10"
    case kCVPixelFormatType_444YpCbCr10:                   return "kCVPixelFormatType_444YpCbCr10"
    case kCVPixelFormatType_420YpCbCr8Planar:              return "kCVPixelFormatType_420YpCbCr8Planar"
    case kCVPixelFormatType_420YpCbCr8PlanarFullRange:     return "kCVPixelFormatType_420YpCbCr8PlanarFullRange"
    case kCVPixelFormatType_422YpCbCr_4A_8BiPlanar:        return "kCVPixelFormatType_422YpCbCr_4A_8BiPlanar"
    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:  return "kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange"
    case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:   return "kCVPixelFormatType_420YpCbCr8BiPlanarFullRange"
    case kCVPixelFormatType_422YpCbCr8_yuvs:               return "kCVPixelFormatType_422YpCbCr8_yuvs"
    case kCVPixelFormatType_422YpCbCr8FullRange:           return "kCVPixelFormatType_422YpCbCr8FullRange"
    case kCVPixelFormatType_OneComponent8:                 return "kCVPixelFormatType_OneComponent8"
    case kCVPixelFormatType_TwoComponent8:                 return "kCVPixelFormatType_TwoComponent8"
    case kCVPixelFormatType_30RGBLEPackedWideGamut:        return "kCVPixelFormatType_30RGBLEPackedWideGamut"
    case kCVPixelFormatType_OneComponent16Half:            return "kCVPixelFormatType_OneComponent16Half"
    case kCVPixelFormatType_OneComponent32Float:           return "kCVPixelFormatType_OneComponent32Float"
    case kCVPixelFormatType_TwoComponent16Half:            return "kCVPixelFormatType_TwoComponent16Half"
    case kCVPixelFormatType_TwoComponent32Float:           return "kCVPixelFormatType_TwoComponent32Float"
    case kCVPixelFormatType_64RGBAHalf:                    return "kCVPixelFormatType_64RGBAHalf"
    case kCVPixelFormatType_128RGBAFloat:                  return "kCVPixelFormatType_128RGBAFloat"
    case kCVPixelFormatType_14Bayer_GRBG:                  return "kCVPixelFormatType_14Bayer_GRBG"
    case kCVPixelFormatType_14Bayer_RGGB:                  return "kCVPixelFormatType_14Bayer_RGGB"
    case kCVPixelFormatType_14Bayer_BGGR:                  return "kCVPixelFormatType_14Bayer_BGGR"
    case kCVPixelFormatType_14Bayer_GBRG:                  return "kCVPixelFormatType_14Bayer_GBRG"
    default: return "UNKNOWN"
    }
}

// for non-planar buffers with raw pixel data inside
public func CVPixelBufferToData(pixelBuffer: CVPixelBuffer) -> Data
{
    CVPixelBufferLockBaseAddress(pixelBuffer, [.readOnly])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, [.readOnly]) }

    let totalSize = CVPixelBufferGetDataSize(pixelBuffer)

    guard let rawFrame = malloc(totalSize) else { fatalError() }
    let dest = rawFrame

    let source = CVPixelBufferGetBaseAddress(pixelBuffer)
    memcpy(dest, source, totalSize)

    return Data(bytesNoCopy: rawFrame, count: totalSize, deallocator: .free)
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
        guard sampleBuffer.isValid else { return }
        
        // Determine which type of data the sample buffer contains.
        switch type {
        case .screen:
           let frame = ProcessVideoBuffer(buffer: sampleBuffer)
            if (frame != nil && UploadClient.instance.GetState() == UploadClientState.CONNECTED)
            {
                UploadClient.instance.SendFrame(frame: frame!)
            }
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
        
        lastFrame = CIImage(cvPixelBuffer: pixelBuffer)
        NotificationCenter.default.post(name: NextFrameReady, object: nil)

        let rawBuffer = CVPixelBufferToData(pixelBuffer: pixelBuffer)
        
        let w = CVPixelBufferGetWidth(pixelBuffer)
        let h = CVPixelBufferGetHeight(pixelBuffer)
        return CapturedFrame(bytes: rawBuffer, width: w, height: h)
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
    if (SCMgr.SharableDisplays.count == 0)
    {
        print(printlabel, "No sharable displays found, can't start capture")
        return
    }
    
    let display = SCMgr.SharableDisplays[0]
    SCMgr.StreamConfig.showsCursor = true
    SCMgr.StreamConfig.pixelFormat = SCREEN_CAPTURE_VIDEO_FORMAT
    SCMgr.StreamConfig.width = display.width
    SCMgr.StreamConfig.height = display.height
    SCMgr.StreamConfig.minimumFrameInterval = CMTime(value: 1, timescale: SCREEN_CAPTURE_FPS)
    SCMgr.StreamConfig.queueDepth = 3
    
    // Note: SCContentFilter/SCStream is bugged, it doesn't work when there are 0 excludingApplications & 0 exceptingWindows
    let excludedApps = SCMgr.SharableApps.filter { app in
        Bundle.main.bundleIdentifier == app.bundleIdentifier
    }
    
    let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])
    let stream = SCStream(filter: filter, configuration: SCMgr.StreamConfig, delegate: ScreenShareStreamEventsHandler.instance)
    SCMgr.Stream = stream
    
    try! stream.addStreamOutput(SCMgr.ScreenShareOuputReciever, type: SCStreamOutputType.screen, sampleHandlerQueue: nil)
    
    UploadClient.instance.ConnectToRelay()
    
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
