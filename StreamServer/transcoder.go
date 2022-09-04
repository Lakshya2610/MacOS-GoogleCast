package main

import (
	"io"
	"io/fs"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type Transcoder struct {
	process          *exec.Cmd
	inputStream      io.WriteCloser
	retainedSegments int
}

var SegmentMatcher = regexp.MustCompile(`([A-Za-z])+(\d)*(\.)(ts)`)

func (t *Transcoder) Run(newFrameNotification <-chan bool) {

	Log(PrintChannelInfo, "Transcoder loop running")

	segmentCleanerExitNoti := make(chan bool)
	// go DeleteUselessSegments(segmentCleanerExitNoti)

	defer func() {
		segmentCleanerExitNoti <- true
	}()
	defer t.process.Process.Kill()

	for {
		nextFrame := frameQueue.Remove()
		if nextFrame != nil {
			_, err := t.inputStream.Write(*nextFrame.data)
			if err != nil {
				Log(PrintChannelError, "Error passing frame to transcoder")
				Log(PrintChannelError, err.Error())
				return
			}
		}

		<-newFrameNotification
	}
}

func GetSegmentsToKeep(manifestName string) map[string]bool {
	f, err := os.Open("media/" + manifestName)
	defer f.Close()

	if err != nil {
		Log(PrintChannelError, "Couldn't open mainfest file")
		Log(PrintChannelError, err.Error())
		return nil
	}

	data, err := io.ReadAll(f)
	if err != nil {
		Log(PrintChannelError, "Couldn't read mainfest file")
		Log(PrintChannelError, err.Error())
		return nil
	}

	dataStr := string(data)
	segmentNames := SegmentMatcher.FindAllString(dataStr, -1)
	if segmentNames != nil {
		out := make(map[string]bool)
		for _, name := range segmentNames {
			out[name] = true
		}

		return out
	}

	return nil
}

func DeleteUselessSegments(exitNotification <-chan bool) {
	for {
		mediaDir, err := os.ReadDir("media")
		if err != nil {
			Log(PrintChannelError, "DeleteUselessSegments: Failed to scan media directory")
			Log(PrintChannelError, err.Error())
		} else {
			var manifest fs.DirEntry
			for _, entry := range mediaDir {
				if entry.IsDir() {
					continue
				}

				if strings.HasSuffix(entry.Name(), ".m3u8") {
					manifest = entry
					break
				}
			}

			var segmentsToKeep map[string]bool = nil
			if manifest != nil {
				segmentsToKeep = GetSegmentsToKeep(manifest.Name())
			}

			if segmentsToKeep != nil {
				for _, entry := range mediaDir {
					if entry.IsDir() {
						continue
					}

					if _, ok := segmentsToKeep[entry.Name()]; !ok && strings.HasSuffix(entry.Name(), ".ts") {
						// a segment file (.ts) that isn't needed
						err := os.Remove("media/" + entry.Name())
						if err != nil {
							Log(PrintChannelError, "Couldn't delete media segment "+entry.Name())
							Log(PrintChannelError, err.Error())
						}
					}
				}

			} else {
				Log(PrintChannelInfo, "Couldn't get any segments to keep, so won't delete any")
			}
		}

		select {
		case <-exitNotification:
			return
		default:
			time.Sleep(time.Duration(time.Duration.Seconds(1)))
		}
	}
}

func NewTranscoder(segmentsToRetain int) *Transcoder {
	transcoder := Transcoder{}

	cmd := exec.Command("ffmpeg",
		"-f", "rawvideo",
		"-pix_fmt", "bgra",
		"-video_size", "1440x900",
		"-i", "pipe:0",
		"-c:v", "libx264",
		"-x264opts", "keyint=30:no-scenecut",
		"-s", "1440x900",
		"-r", "60",
		"-profile:v", "high444",
		"-hls_time", "1",
		"-hls_list_size", strconv.Itoa(segmentsToRetain), "media/out.m3u8")

	inputStream, err := cmd.StdinPipe()
	if err != nil {
		Log(PrintChannelError, "Error launching transcoder")
		Log(PrintChannelError, err.Error())
		cmd.Process.Kill()
		return nil
	}

	transcoder.process = cmd
	transcoder.inputStream = inputStream
	transcoder.process.Stdout = os.Stdout
	transcoder.retainedSegments = segmentsToRetain

	err = transcoder.process.Start()
	if err != nil {
		Log(PrintChannelError, "Error launching ffmpeg process")
		Log(PrintChannelError, err.Error())
		return nil
	}

	return &transcoder
}
