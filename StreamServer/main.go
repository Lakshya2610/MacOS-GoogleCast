package main

import (
	"flag"
	"fmt"
	"io"
	"net/http"

	"github.com/gorilla/websocket"
)

var listenAddr string
var WSConnUpgrader = websocket.Upgrader{CheckOrigin: CheckWSConnectionOrigin}

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
	go relay.Run(&Client{connection: ws})
}

func GetVideo(response http.ResponseWriter, request *http.Request) {
	response.Header().Set("Content-Type", "application/octet-stream")
	response.WriteHeader(http.StatusPartialContent)

	frame := frameQueue.Remove()
	if frame == nil {
		return
	}

	response.Write(*frame.data)
}

func Default(response http.ResponseWriter, request *http.Request) {
	Log(PrintChannelInfo, "Got a new request for default route")
	io.WriteString(response, "Hello, world!")
}

func TestRoute(response http.ResponseWriter, request *http.Request) {
	http.ServeFile(response, request, "test.mp4")
}

func main() {
	http.HandleFunc("/", Default)
	http.HandleFunc("/relay", VideoRelay)
	http.HandleFunc("/video", GetVideo)
	http.HandleFunc("/test", TestRoute)

	Log(PrintChannelInfo, "Server is starting.  Press CTRL-C to exit.")
	err := http.ListenAndServe(listenAddr, nil)
	if err == http.ErrServerClosed {
		Log(PrintChannelError, err.Error())
		return
	}
}
