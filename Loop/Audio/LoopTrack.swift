import AVFoundation

protocol LoopTrackDelegate: AnyObject {
    func trackStateChanged(_ track: LoopTrack)
    func loopLengthDetermined(_ length: AVAudioFrameCount)
    var currentLoopLength: AVAudioFrameCount { get }
}

final class LoopTrack: Identifiable {
    let id = UUID()
    let index: Int
    let playerNode: AVAudioPlayerNode
    let format: AVAudioFormat

    weak var delegate: LoopTrackDelegate?

    private(set) var state: TrackState = .empty

    private var mainBuffer: AVAudioPCMBuffer?
    private var recordingChunks: [AVAudioPCMBuffer] = []
    private var overdubStartOffset: AVAudioFrameCount = 0

    private var undoStack: [AVAudioPCMBuffer] = []
    private let maxUndoSteps = 20

    var volume: Float = 0.8 {
        didSet { applyVolume() }
    }
    var isMuted: Bool = false {
        didSet { applyVolume() }
    }

    var hasContent: Bool {
        return mainBuffer != nil
    }

    var duration: TimeInterval {
        guard let buffer = mainBuffer else { return 0 }
        return TimeInterval(buffer.frameLength) / format.sampleRate
    }

    init(index: Int, format: AVAudioFormat) {
        self.index = index
        self.format = format
        self.playerNode = AVAudioPlayerNode()
    }

    private func applyVolume() {
        playerNode.volume = isMuted ? 0 : volume
    }

    private func notifyStateChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.trackStateChanged(self)
        }
    }

    func setState(_ newState: TrackState) {
        state = newState
        notifyStateChange()
    }

    func startRecording() {
        guard state == .empty else { return }
        recordingChunks = []
        state = .recording
        notifyStateChange()
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        if state == .recording || state == .overdubbing {
            let copy = copyBuffer(buffer)
            recordingChunks.append(copy)

            if state == .recording {
                let total = recordingChunks.reduce(0) { $0 + Int($1.frameLength) }
                let loopLen = delegate?.currentLoopLength ?? 0
                if loopLen > 0 && total >= Int(loopLen) {
                    finishRecording()
                }
            }
        }
    }

    func finishRecording() {
        guard state == .recording else { return }

        let totalFrames = recordingChunks.reduce(0) { $0 + Int($1.frameLength) }
        guard totalFrames > 0 else {
            recordingChunks = []
            state = .empty
            notifyStateChange()
            return
        }

        let loopLen = delegate?.currentLoopLength ?? 0
        let targetFrames = loopLen > 0 ? min(totalFrames, Int(loopLen)) : totalFrames

        guard let combined = createBuffer(frameCount: AVAudioFrameCount(targetFrames)) else {
            recordingChunks = []
            state = .empty
            notifyStateChange()
            return
        }

        copyChunksInto(chunks: recordingChunks, destination: combined, maxFrames: targetFrames)

        mainBuffer = combined
        recordingChunks = []

        if loopLen == 0 {
            delegate?.loopLengthDetermined(combined.frameLength)
        }

        state = .playing
        startLooping()
        notifyStateChange()
    }

    func startOverdubbing() {
        guard state == .playing, mainBuffer != nil else { return }

        if let renderTime = playerNode.lastRenderTime,
           let playerTime = playerNode.playerTime(forNodeTime: renderTime) {
            let loopLen = mainBuffer!.frameLength
            overdubStartOffset = AVAudioFrameCount(Int(playerTime.sampleTime) % Int(loopLen))
        } else {
            overdubStartOffset = 0
        }

        recordingChunks = []
        state = .overdubbing
        notifyStateChange()
    }

    func finishOverdubbing() {
        guard state == .overdubbing else { return }

        let totalFrames = recordingChunks.reduce(0) { $0 + Int($1.frameLength) }

        if totalFrames > 0, let main = mainBuffer {
            if let overdubBuffer = createBuffer(frameCount: AVAudioFrameCount(totalFrames)) {
                copyChunksInto(chunks: recordingChunks, destination: overdubBuffer, maxFrames: totalFrames)
                saveUndoState()
                mixOverdub(overdubBuffer, into: main, startPosition: Int(overdubStartOffset))
            }
        }

        recordingChunks = []

        playerNode.stop()
        startLooping()

        state = .playing
        notifyStateChange()
    }

    func startLooping() {
        guard let buffer = mainBuffer else { return }
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    func startPlayback() {
        guard mainBuffer != nil else { return }
        if state == .empty || state == .stopped {
            state = .playing
            startLooping()
            notifyStateChange()
        }
    }

    func stopForMaster() {
        if state == .overdubbing {
            finishOverdubbing()
        }
        if state == .playing || state == .overdubbing {
            playerNode.stop()
            state = .stopped
            notifyStateChange()
        }
    }

    func clear() {
        playerNode.stop()
        mainBuffer = nil
        undoStack = []
        recordingChunks = []
        state = .empty
        notifyStateChange()
    }

    func canUndo() -> Bool {
        return !undoStack.isEmpty
    }

    func undo() {
        guard !undoStack.isEmpty, mainBuffer != nil else { return }

        let previous = undoStack.removeLast()
        mainBuffer = previous

        if state == .playing {
            playerNode.stop()
            startLooping()
        }

        notifyStateChange()
    }

    private func saveUndoState() {
        guard let buffer = mainBuffer else { return }
        guard let copy = createBuffer(frameCount: buffer.frameLength) else { return }
        copy.frameLength = buffer.frameLength

        let bytesPerFrame = Int(format.streamDescription.pointee.mBytesPerFrame)
        if let src = buffer.audioBufferList.pointee.mBuffers.mData,
           let dst = copy.audioBufferList.pointee.mBuffers.mData {
            memcpy(dst, src, Int(buffer.frameLength) * bytesPerFrame)
        }

        undoStack.append(copy)
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
    }

    private func mixOverdub(_ overdub: AVAudioPCMBuffer, into main: AVAudioPCMBuffer, startPosition: Int) {
        let mainLength = Int(main.frameLength)
        let overdubLength = Int(overdub.frameLength)

        guard let mainData = main.floatChannelData,
              let overdubData = overdub.floatChannelData else { return }

        for i in 0..<overdubLength {
            let mainIndex = (startPosition + i) % mainLength
            let mixed = mainData[0][mainIndex] + overdubData[0][i]
            mainData[0][mainIndex] = max(-1.0, min(1.0, mixed))
        }
    }

    private func createBuffer(frameCount: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
    }

    private func copyBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer {
        let copy = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameLength)!
        copy.frameLength = buffer.frameLength
        let bytesPerFrame = Int(format.streamDescription.pointee.mBytesPerFrame)
        if let src = buffer.audioBufferList.pointee.mBuffers.mData,
           let dst = copy.audioBufferList.pointee.mBuffers.mData {
            memcpy(dst, src, Int(buffer.frameLength) * bytesPerFrame)
        }
        return copy
    }

    private func copyChunksInto(chunks: [AVAudioPCMBuffer], destination: AVAudioPCMBuffer, maxFrames: Int) {
        guard let destData = destination.floatChannelData else { return }

        var offset = 0
        for chunk in chunks {
            let frames = Int(chunk.frameLength)
            let remaining = maxFrames - offset
            let toCopy = min(frames, remaining)
            if toCopy <= 0 { break }

            guard let srcData = chunk.floatChannelData else { continue }
            memcpy(destData[0] + offset, srcData[0], toCopy * MemoryLayout<Float>.size)
            offset += toCopy
        }
        destination.frameLength = AVAudioFrameCount(offset)
    }

    func getAudioData() -> (data: Data, frameLength: AVAudioFrameCount)? {
        guard let buffer = mainBuffer else { return nil }
        let bytesPerFrame = Int(format.streamDescription.pointee.mBytesPerFrame)
        let dataSize = Int(buffer.frameLength) * bytesPerFrame
        guard let baseAddress = buffer.audioBufferList.pointee.mBuffers.mData else { return nil }
        let data = Data(bytes: baseAddress, count: dataSize)
        return (data, buffer.frameLength)
    }

    func loadAudioData(_ data: Data, frameLength: AVAudioFrameCount) {
        guard let buffer = createBuffer(frameCount: frameLength) else { return }
        buffer.frameLength = frameLength

        let bytesPerFrame = Int(format.streamDescription.pointee.mBytesPerFrame)
        data.withUnsafeBytes { ptr in
            if let src = ptr.baseAddress,
               let dst = buffer.audioBufferList.pointee.mBuffers.mData {
                let copySize = min(data.count, Int(frameLength) * bytesPerFrame)
                memcpy(dst, src, copySize)
            }
        }

        mainBuffer = buffer
        state = .stopped
        notifyStateChange()
    }
}
