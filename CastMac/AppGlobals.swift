//
//  AppGlobals.swift
//  CastMac
//
//  Created by Lakshya Gupta on 2022-08-29.
//

import Foundation
import OpenCastSwift
import ScreenCaptureKit

var Client: CastClient? = nil
var AppMonitor: CastAppMonitor? = nil
let APP_MONITOR_INTERVAL_S: UInt8 = 1
let SCREEN_CAPTURE_VIDEO_FORMAT: OSType = kCVPixelFormatType_32BGRA
let SCREEN_CAPTURE_FPS: CMTimeScale = 60
let RELAY_SERVER_URL: String = "ws://localhost:8080/relay"
let RELAY_AUTH_PASSWORD = 0

func VOIDFUNC()
{
    
}
