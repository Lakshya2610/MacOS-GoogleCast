# MacOS-GoogleCast
MacOS app for screen sharing using google cast API

MacOS app built for screen sharing using google cast API. The app uses Apple's [Screen Capture Kit](https://developer.apple.com/documentation/screencapturekit) API
for capturing screen content. Google Cast API's macOS implementation is from [OpenCastSwift](https://github.com/mhmiles/OpenCastSwift).

Since the Cast API doesn't permit streaming video directly from a local device (only from a URL), the app uses a local relay sever (written in Go)
to stream data to a Cast compatible device. The relay uses ffmpeg for realtime transcoding and generating a HLS stream which can then be played by a
cast compatible device.

Note: the app is in a very rough state, I just built it to learn some stuff and test ideas, most of the flow should work, but the app still needs some work
      (on the UI & tech side) to become usable.

To run the app:
- Launch it in XCode (you will need to download [OpenCastSwift](https://github.com/mhmiles/OpenCastSwift) from it's repository and link it)
- Run the StreamServer
- Launch the app in XCode.
- To connect to a cast device, hit Scan and the device should pop-up on the UI as a button. Click on it to connect (Check logs to make sure it worked)
- Once connected, hit refresh display to let the app get sharable displays on your system (you may need to give it permission and restart)
- Hit Screen Share and it should start the screen capture and connect to the relay as well (Again, check logs on both sides to makes sure everything went well)
- Hit media player to launch media player on the Cast display and watch the stream (your screen)

You may have to tweak some ffmpeg parameters to get things to work
