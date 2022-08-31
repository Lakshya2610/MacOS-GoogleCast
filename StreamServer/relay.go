package main

import (
	"bytes"
	"encoding/binary"
	"fmt"

	"github.com/gorilla/websocket"
)

type Client struct {
	connection      *websocket.Conn
	streamWidth     int
	streamHeight    int
	framesProcessed uint64
}

type RelayState uint8

const (
	RELAY_INIT         RelayState = iota
	RELAY_READY        RelayState = iota
	RELAY_CONNECTING   RelayState = iota
	RELAY_CONNECTED    RelayState = iota
	RELAY_DISCONNECTED RelayState = iota
)

const AUTH_MSG string = "RequestPassword"
const STREAM_METADATA_MSG string = "RequestMetadata"
const READY_TO_RECV_FRAMES_MSG string = "ReadyToRecv"

type Relay struct {
	idx          int64
	uploadClient *Client
	state        RelayState
}

func (client *Client) Send(messageID int, message []byte) bool {
	err := client.connection.WriteMessage(messageID, message)
	if err != nil {
		Log(PrintChannelError, "Error requesting auth")
		Log(PrintChannelError, err.Error())
		return false
	}

	return true
}

func (relay *Relay) Run(client *Client) {
	relay.uploadClient = client
	relay.state = RELAY_CONNECTING

	defer client.connection.Close()

	// auth
	if !relay.uploadClient.Send(websocket.TextMessage, []byte(AUTH_MSG)) {
		relay.state = RELAY_DISCONNECTED
		return
	}

	ty, data, err := client.connection.ReadMessage()
	if err != nil || ty != websocket.BinaryMessage {
		Log(PrintChannelError, "Failed to get auth message with uid from client")
		relay.state = RELAY_DISCONNECTED
		return
	}

	idx, err := binary.ReadVarint(bytes.NewReader(data))
	if err != nil {
		Log(PrintChannelError, "Failed to convert message to id for auth, aborting")
		relay.state = RELAY_DISCONNECTED
		return
	}

	if idx != relay.idx {
		Log(PrintChannelInfo, "ID mismatch - failed to authenticate")
		relay.state = RELAY_DISCONNECTED
		return
	}

	relay.state = RELAY_CONNECTED
	frameQueue = FrameQueue{size: DEFAULT_FRAME_QUEUE_SIZE}
	Log(PrintChannelInfo, "Auth success, client connected to relay. Waiting for stream meta data")

	success := relay.GetStreamMetadata()
	if !success {
		relay.state = RELAY_DISCONNECTED
		return
	}

	Log(PrintChannelInfo, fmt.Sprintf("Successfully got stream meta data, frame w: %d frame h: %d", relay.uploadClient.streamWidth, relay.uploadClient.streamHeight))

	if !relay.uploadClient.Send(websocket.TextMessage, []byte(READY_TO_RECV_FRAMES_MSG)) {
		relay.state = RELAY_DISCONNECTED
		return
	}

	client.framesProcessed = 0
	for {
		ty, data, err = client.connection.ReadMessage()
		if err != nil || ty != websocket.BinaryMessage {
			Log(PrintChannelError, "Error processing message from client, closing connection")
			relay.state = RELAY_DISCONNECTED
			break
		}

		Log(PrintChannelInfo, fmt.Sprintf("New frame received, size: %d", len(data)))
		frameQueue.Add(&data)
		client.framesProcessed++
	}
}

func (relay *Relay) GetStreamMetadata() bool {
	if relay.state != RELAY_CONNECTED {
		Log(PrintChannelError, "GetStreamMetadata called when realy doesn't have a valid connection to client")
		return false
	}

	if !relay.uploadClient.Send(websocket.TextMessage, []byte(STREAM_METADATA_MSG)) {
		return false
	}

	ty, data, err := relay.uploadClient.connection.ReadMessage()
	if err != nil || ty != websocket.BinaryMessage {
		Log(PrintChannelError, "Error processing message from client, was expecting stream resolution")
		if err != nil {
			Log(PrintChannelError, err.Error())
		}

		return false
	}

	var packedres uint64 = 0
	err = binary.Read(bytes.NewReader(data), binary.LittleEndian, &packedres)
	if err != nil {
		Log(PrintChannelError, "Error reading integer from data, was expecting packed int64 with res width & height")
		Log(PrintChannelError, err.Error())
		return false
	}

	width := int32(packedres & 0xFFFFFFFF)
	height := int32((packedres & uint64(0xFFFFFFFF00000000)) >> 32)

	relay.uploadClient.streamWidth = int(width)
	relay.uploadClient.streamHeight = int(height)

	return true
}
