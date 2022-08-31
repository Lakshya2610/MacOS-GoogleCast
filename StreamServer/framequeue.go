package main

const DEFAULT_FRAME_QUEUE_SIZE uint = 3

var frameQueue FrameQueue

type Frame struct {
	data *[]byte
	next *Frame
}

type FrameQueue struct {
	size   uint
	length int
	front  *Frame
	back   *Frame
}

func (queue *FrameQueue) Add(framedata *[]byte) {
	// push out oldest frame
	if queue.length == int(queue.size) {
		oldestFrame := queue.front
		if oldestFrame != nil {
			queue.front = oldestFrame.next
		} else {
			queue.front = nil
		}

		if oldestFrame == queue.back {
			queue.back = nil
		}
		queue.length--
	}

	newFrame := Frame{data: framedata, next: nil}
	if queue.back != nil {
		queue.back.next = &newFrame
	}

	queue.back = &newFrame

	if queue.length == 0 {
		queue.front = &newFrame
	}

	queue.length++
}

func (queue *FrameQueue) Remove() *Frame {
	if queue.length == 0 {
		return nil
	}

	outFrame := queue.front
	queue.front = queue.front.next
	if queue.front == nil {
		queue.back = nil
	}

	queue.length--

	return outFrame
}
