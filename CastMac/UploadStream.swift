//
//  UploadStream.swift
//  CastMac
//
//  Created by Lakshya Gupta on 2022-08-31.
//

import Foundation

private let printlabel: String = "[UPLOAD_CLIENT]"

private let AUTH_MSG = "RequestPassword"
private let STREAM_METADATA_MSG = "RequestMetadata"
private let READY_TO_RECV_FRAMES_MSG = "ReadyToRecv"

public enum UploadClientState : uint8
{
    case INIT = 0
    case READY_TO_CONNECT
    case AUTHENTICATING
    case WAITING_TO_SEND_METADATA
    case META_DATA_SENT
    case CONNECTED
    case DISCONNECTED
}

class UploadClient
{
    // singleton instance
    public static let instance = UploadClient()
    
    private var m_socket: URLSessionWebSocketTask
    private var m_state: UploadClientState = UploadClientState.INIT
    private var m_framesSent: UInt64 = 0
    
    init()
    {
        m_socket = URLSession.shared.webSocketTask(with: URL(string: RELAY_SERVER_URL)!)
        m_state = UploadClientState.READY_TO_CONNECT
        m_framesSent = 0
    }
    
    public func GetState() -> UploadClientState
    {
        return m_state
    }
    
    public func ConnectToRelay()
    {
        Listen()
        self.m_socket.resume()
        self.m_state = UploadClientState.AUTHENTICATING
    }
    
    private func Listen()
    {
        m_socket.receive { (result) in
            switch result {
                case .failure(let error):
                    print(error)
                    break
                case .success(let message):
                    switch message {
                        case .data:
                            print(printlabel, "Got unexpected message from relay, ignoring")
                            break
                        case .string(let str):
                            guard let _ = str.data(using: .utf8) else { return }
                            print(printlabel, "Recv message from relay", str)
                            self.HandleRelayMessage(msg: str)
                            break
                        @unknown default:
                            break
                    }
            }
            
            self.Listen()
        }
    }
    
    private func HandleRelayMessage(msg: String)
    {
        if (msg == AUTH_MSG)
        {
            var password = RELAY_AUTH_PASSWORD
            let reply = Data(bytes: &password, count: MemoryLayout<Int>.size)
            SendToRelay(reply: reply, newState: UploadClientState.WAITING_TO_SEND_METADATA)
        }
        else if (msg == STREAM_METADATA_MSG)
        {
            let h = UInt64(SCMgr.StreamConfig.height) << 32
            var packedRes: UInt64 = UInt64(SCMgr.StreamConfig.width) | h
            let reply = Data(bytes: &packedRes, count: MemoryLayout<UInt64>.size)
            SendToRelay(reply: reply, newState: UploadClientState.META_DATA_SENT)
        }
        else if (msg == READY_TO_RECV_FRAMES_MSG)
        {
            m_state = UploadClientState.CONNECTED
            print(printlabel, "Relay connection success, ready to send frames")
        }
    }
    
    private func SendToRelay(reply: Data, newState: UploadClientState?)
    {
        self.m_socket.send(URLSessionWebSocketTask.Message.data( reply ) )
        { err in
            if (err != nil)
            {
                print(printlabel, "Failed to send reply to relay -", err ?? "")
                self.m_state = UploadClientState.DISCONNECTED
                self.m_socket.cancel(with: URLSessionWebSocketTask.CloseCode.normalClosure, reason: nil)
                return
            }
            
            if (newState != nil)
            {
                self.m_state = newState!
            }
        }
    }
    
    public func SendFrame(frame: CapturedFrame)
    {
        if (m_state != UploadClientState.CONNECTED)
        {
            print(printlabel, "SendFrame Called when connection is not ready to receive frame data")
            return
        }
        
        SendToRelay(reply: frame.bytes, newState: nil)
        m_framesSent += 1
    }
}
