# MacOS-GoogleCast
MacOS app for screen sharing using google cast API

MacOS app built for screen sharing using google cast API. The app uses Apple's [Screen Capture Kit](https://developer.apple.com/documentation/screencapturekit) API
for capturing screen content. Google Cast API's macOS implementation is from [OpenCastSwift](https://github.com/mhmiles/OpenCastSwift).

Since the Cast API doesn't permit streaming video directly from a local device (only from a URL), the app uses a local relay sever (written in Go)
to stream data to a Cast compatible device. The relay uses ffmpeg for realtime transcoding and generating a HLS stream which can then be played by a
cast compatible device.

Note: the app is in very rough state, I just built it to learn some stuff and test ideas, most of the flow should work, but the app still needs some work
      (on the UI & tech side) to become usable.
