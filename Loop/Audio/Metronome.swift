import AVFoundation

final class Metronome {
    private var timer: Timer?
    private let playerNode: AVAudioPlayerNode
    private let format: AVAudioFormat
    private var clickBuffer: AVAudioPCMBuffer?

    private(set) var isPlaying: Bool = false
    var bpm: Double = 120

    init(playerNode: AVAudioPlayerNode, format: AVAudioFormat) {
        self.playerNode = playerNode
        self.format = format
        generateClick()
    }

    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        scheduleClicks()
    }

    func stop() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    func setBPM(_ newBPM: Double) {
        bpm = max(40, min(300, newBPM))
        if isPlaying {
            stop()
            start()
        }
    }

    private func scheduleClicks() {
        let interval = 60.0 / bpm
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.playClick()
        }
    }

    private func playClick() {
        guard let buffer = clickBuffer else { return }
        playerNode.scheduleBuffer(buffer, at: nil, options: [])
    }

    private func generateClick() {
        let sampleRate = format.sampleRate
        let clickDuration: Double = 0.015
        let clickFrames = AVAudioFrameCount(sampleRate * clickDuration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: clickFrames) else { return }
        buffer.frameLength = clickFrames

        guard let data = buffer.floatChannelData else { return }
        let freq: Double = 1500
        for i in 0..<Int(clickFrames) {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 300)
            data[0][i] = Float(sin(2.0 * .pi * freq * t) * envelope * 0.3)
        }
        self.clickBuffer = buffer
    }
}
