import AVFoundation

final class AudioEngine {
    let engine = AVAudioEngine()
    let format: AVAudioFormat

    let masterMixer: AVAudioMixerNode
    let monitorMixer: AVAudioMixerNode
    let reverbNode: AVAudioUnitReverb
    let delayNode: AVAudioUnitDelay
    let metronomePlayer: AVAudioPlayerNode

    let metronome: Metronome
    let tracks: [LoopTrack]

    private(set) var loopLength: AVAudioFrameCount = 0
    private(set) var isMonitoring: Bool = false
    private(set) var isRunning: Bool = false

    private var recordingTrackIndex: Int? = nil

    var onStateChanged: (() -> Void)?

    init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        masterMixer = AVAudioMixerNode()
        monitorMixer = AVAudioMixerNode()
        reverbNode = AVAudioUnitReverb()
        delayNode = AVAudioUnitDelay()
        metronomePlayer = AVAudioPlayerNode()

        tracks = (0..<6).map { LoopTrack(index: $0, format: format) }
        metronome = Metronome(playerNode: metronomePlayer, format: format)

        setupEngine()
        setupInterruptionHandling()
    }

    private func setupEngine() {
        engine.attach(masterMixer)
        engine.attach(monitorMixer)
        engine.attach(reverbNode)
        engine.attach(delayNode)
        engine.attach(metronomePlayer)

        engine.connect(masterMixer, to: reverbNode, format: format)
        engine.connect(reverbNode, to: delayNode, format: format)
        engine.connect(delayNode, to: engine.outputNode, format: format)

        engine.connect(engine.inputNode, to: monitorMixer, format: format)
        engine.connect(monitorMixer, to: masterMixer, format: format)
        monitorMixer.outputVolume = 0

        engine.connect(metronomePlayer, to: masterMixer, format: format)

        for track in tracks {
            engine.attach(track.playerNode)
            engine.connect(track.playerNode, to: masterMixer, format: format)
            track.delegate = self
        }

        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 20
        delayNode.delayTime = 0.3
        delayNode.feedback = 35
        delayNode.wetDryMix = 20
    }

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            stopAll()
            engine.stop()
            isRunning = false
        case .ended:
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    start()
                }
            }
        @unknown default:
            break
        }
    }

    func start() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setPreferredIOBufferDuration(0.005)
        try? session.setActive(true)

        do {
            try engine.start()
            isRunning = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func stop() {
        engine.stop()
        isRunning = false
    }

    func toggleTrack(_ index: Int) {
        guard index >= 0 && index < tracks.count else { return }
        let track = tracks[index]

        switch track.state {
        case .empty, .stopped:
            if recordingTrackIndex == nil {
                startRecording(on: index)
            }
        case .recording:
            track.finishRecording()
            removeInputTap()
            recordingTrackIndex = nil
        case .playing:
            if recordingTrackIndex == nil {
                startOverdub(on: index)
            }
        case .overdubbing:
            track.finishOverdubbing()
            removeInputTap()
            recordingTrackIndex = nil
        }
    }

    private func startRecording(on index: Int) {
        recordingTrackIndex = index
        let track = tracks[index]
        if track.state == .stopped {
            track.clear()
        }
        track.startRecording()
        installInputTap()
    }

    private func startOverdub(on index: Int) {
        recordingTrackIndex = index
        tracks[index].startOverdubbing()
        installInputTap()
    }

    private func installInputTap() {
        engine.inputNode.removeTap(onBus: 0)
        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self, let trackIndex = self.recordingTrackIndex else { return }
            self.tracks[trackIndex].appendAudioBuffer(buffer)
        }
    }

    private func removeInputTap() {
        engine.inputNode.removeTap(onBus: 0)
    }

    func startAll() {
        for track in tracks {
            track.startPlayback()
        }
    }

    func stopAll() {
        if recordingTrackIndex != nil {
            let idx = recordingTrackIndex!
            if tracks[idx].state == .recording {
                tracks[idx].finishRecording()
            } else if tracks[idx].state == .overdubbing {
                tracks[idx].finishOverdubbing()
            }
            removeInputTap()
            recordingTrackIndex = nil
        }
        for track in tracks {
            track.stopForMaster()
        }
    }

    func undoLast() {
        for track in tracks.reversed() {
            if track.canUndo() {
                track.undo()
                return
            }
        }
    }

    func clearTrack(_ index: Int) {
        guard index >= 0 && index < tracks.count else { return }
        if recordingTrackIndex == index {
            removeInputTap()
            recordingTrackIndex = nil
        }
        tracks[index].clear()

        let anyHasContent = tracks.contains { $0.hasContent }
        if !anyHasContent {
            loopLength = 0
        }
    }

    func toggleMonitoring() {
        isMonitoring.toggle()
        monitorMixer.outputVolume = isMonitoring ? 1.0 : 0.0
    }

    func toggleMetronome() {
        if metronome.isPlaying {
            metronome.stop()
        } else {
            metronome.start()
        }
    }

    func setBPM(_ bpm: Double) {
        metronome.setBPM(bpm)
    }

    func setReverbMix(_ mix: Float) {
        reverbNode.wetDryMix = mix
    }

    func setDelayMix(_ mix: Float) {
        delayNode.wetDryMix = mix
    }

    func setTrackVolume(_ index: Int, volume: Float) {
        guard index >= 0 && index < tracks.count else { return }
        tracks[index].volume = volume
    }

    func setTrackMute(_ index: Int, muted: Bool) {
        guard index >= 0 && index < tracks.count else { return }
        tracks[index].isMuted = muted
    }

    func exportMix() -> URL? {
        let maxFrames = tracks.compactMap { $0.mainBuffer?.frameLength }.max() ?? 0
        guard maxFrames > 0 else { return nil }

        guard let mixBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: maxFrames) else { return nil }
        mixBuffer.frameLength = maxFrames

        guard let destData = mixBuffer.floatChannelData else { return nil }
        for i in 0..<Int(maxFrames) {
            destData[0][i] = 0
        }

        for track in tracks {
            guard let buffer = track.mainBuffer else { continue }
            let frames = Int(buffer.frameLength)
            guard let srcData = buffer.floatChannelData else { continue }
            let vol = track.isMuted ? Float(0) : track.volume

            for i in 0..<frames {
                destData[0][i] += srcData[0][i] * vol
            }
        }

        for i in 0..<Int(maxFrames) {
            destData[0][i] = max(-1.0, min(1.0, destData[0][i]))
        }

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("loop_export_\(Int(Date().timeIntervalSince1970)).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        guard let file = try? AVAudioFile(forWriting: url, settings: settings) else { return nil }
        do {
            try file.write(from: mixBuffer)
            return url
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var projectsDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("LoopProjects")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func saveProject(named name: String) {
        let projectDir = projectsDirectory.appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)

        var trackInfos: [[String: Any]] = []
        for (i, track) in tracks.enumerated() {
            if let audioData = track.getAudioData() {
                let fileURL = projectDir.appendingPathComponent("track_\(i).pcm")
                try? audioData.data.write(to: fileURL)
                trackInfos.append([
                    "index": i,
                    "hasContent": true,
                    "frameLength": Int(audioData.frameLength),
                    "volume": Double(track.volume),
                    "isMuted": track.isMuted
                ])
            } else {
                trackInfos.append([
                    "index": i,
                    "hasContent": false
                ])
            }
        }

        let projectInfo: [String: Any] = [
            "name": name,
            "bpm": Double(metronome.bpm),
            "loopLength": Int(loopLength),
            "tracks": trackInfos,
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ]

        let metadataURL = projectDir.appendingPathComponent("project.json")
        if let jsonData = try? JSONSerialization.data(withJSONObject: projectInfo, options: .prettyPrinted) {
            try? jsonData.write(to: metadataURL)
        }
    }

    func loadProject(named name: String) {
        let projectDir = projectsDirectory.appendingPathComponent(name)
        let metadataURL = projectDir.appendingPathComponent("project.json")

        guard let data = try? Data(contentsOf: metadataURL),
              let info = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        stopAll()

        if let bpm = info["bpm"] as? Double {
            metronome.setBPM(bpm)
        }
        if let len = info["loopLength"] as? Int {
            loopLength = AVAudioFrameCount(len)
        }

        guard let trackInfos = info["tracks"] as? [[String: Any]] else { return }
        for trackInfo in trackInfos {
            guard let index = trackInfo["index"] as? Int,
                  index >= 0 && index < tracks.count else { continue }

            if trackInfo["hasContent"] as? Bool == true,
               let frameLength = trackInfo["frameLength"] as? Int {
                let fileURL = projectDir.appendingPathComponent("track_\(index).pcm")
                if let audioData = try? Data(contentsOf: fileURL) {
                    tracks[index].loadAudioData(audioData, frameLength: AVAudioFrameCount(frameLength))
                }
                if let volume = trackInfo["volume"] as? Double {
                    tracks[index].volume = Float(volume)
                }
                if let muted = trackInfo["isMuted"] as? Bool {
                    tracks[index].isMuted = muted
                }
            }
        }
    }

    func listProjects() -> [String] {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return contents
            .filter { $0.hasDirectoryPath }
            .map { $0.lastPathComponent }
            .sorted()
    }

    func deleteProject(named name: String) {
        let projectDir = projectsDirectory.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: projectDir)
    }
}

extension AudioEngine: LoopTrackDelegate {
    func trackStateChanged(_ track: LoopTrack) {
        DispatchQueue.main.async { [weak self] in
            self?.onStateChanged?()
        }
    }

    func loopLengthDetermined(_ length: AVAudioFrameCount) {
        DispatchQueue.main.async { [weak self] in
            self?.loopLength = length
        }
    }

    var currentLoopLength: AVAudioFrameCount {
        return loopLength
    }
}
