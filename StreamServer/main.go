package main

import (
	"flag"
	"fmt"
	"net/http"

	"github.com/gorilla/websocket"
)

var listenAddr string
var WSConnUpgrader = websocket.Upgrader{CheckOrigin: CheckWSConnectionOrigin}
var shouldRecordStream bool
var newFrameNotification chan bool
var transcoder *Transcoder

var relay Relay = Relay{state: RELAY_INIT}

const PrintChannelInfo string = "[INFO]: "
const PrintChannelError string = "[ERROR]: "

func Log(channel string, msg string) {
	switch channel {
	case PrintChannelInfo, PrintChannelError:
		fmt.Println(channel + msg)
		break
	default:
		fmt.Println(msg)
	}
}

func CheckWSConnectionOrigin(r *http.Request) bool {
	Log(PrintChannelInfo, "incoming connection from origin "+r.RemoteAddr)
	return true
}

func init() {
	flag.StringVar(&listenAddr, "addr", ":8080", "http service address")
	flag.BoolVar(&shouldRecordStream, "record", false, "record incoming stream")
}

func VideoRelay(response http.ResponseWriter, request *http.Request) {
	if relay.state != RELAY_INIT && relay.state != RELAY_DISCONNECTED {
		Log(PrintChannelInfo, "Relay already active, stop the existing session before starting a new one")
		return
	}

	ws, err := WSConnUpgrader.Upgrade(response, request, nil)
	if err != nil {
		Log(PrintChannelError, "Failed to upgrade connection to ws connection for client "+request.RemoteAddr)
		Log(PrintChannelError, err.Error())
		return
	}

	relay = Relay{state: RELAY_CONNECTING, idx: 0}
	go relay.Run(&Client{connection: ws, shouldRecordStream: shouldRecordStream}, newFrameNotification)
}

func AllowCORS(h http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		h.ServeHTTP(w, r)
	}
}

func main() {
	flag.Parse()
	newFrameNotification = make(chan bool)
	if shouldRecordStream {
		Log(PrintChannelInfo, "Recording enabled")
	}

	http.HandleFunc("/relay", VideoRelay)
	http.Handle("/", AllowCORS(http.FileServer(http.Dir("media"))))

	transcoder = NewTranscoder(2)
	go transcoder.Run(newFrameNotification)

	Log(PrintChannelInfo, "Server is starting.  Press CTRL-C to exit.")
	err := http.ListenAndServe(listenAddr, nil)
	if err == http.ErrServerClosed {
		Log(PrintChannelError, err.Error())
		return
	}
}
