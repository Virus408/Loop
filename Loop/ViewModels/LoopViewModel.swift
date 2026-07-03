import Foundation
import SwiftUI
import AVFoundation

final class LoopViewModel: ObservableObject {
    let audioEngine: AudioEngine

    @Published var trackStates: [TrackState] = Array(repeating: .empty, count: 6)
    @Published var trackVolumes: [Float] = Array(repeating: 0.8, count: 6)
    @Published var trackMuted: [Bool] = Array(repeating: false, count: 6)
    @Published var trackDurations: [TimeInterval] = Array(repeating: 0, count: 6)

    @Published var isMonitoring: Bool = false
    @Published var isMetronomeOn: Bool = false
    @Published var bpm: Double = 120
    @Published var reverbMix: Float = 20
    @Published var delayMix: Float = 20

    @Published var savedProjects: [String] = []
    @Published var showingSaveDialog: Bool = false
    @Published var showingLoadDialog: Bool = false
    @Published var showingEffects: Bool = false

    private var isUpdatingFromEngine = false

    init() {
        audioEngine = AudioEngine()
        audioEngine.onStateChanged = { [weak self] in
            self?.syncFromEngine()
        }
        audioEngine.start()
        refreshProjects()
    }

    func toggleTrack(_ index: Int) {
        audioEngine.toggleTrack(index)
        syncFromEngine()
    }

    func clearTrack(_ index: Int) {
        audioEngine.clearTrack(index)
        syncFromEngine()
    }

    func startAll() {
        audioEngine.startAll()
        syncFromEngine()
    }

    func stopAll() {
        audioEngine.stopAll()
        syncFromEngine()
    }

    func undoLast() {
        audioEngine.undoLast()
        syncFromEngine()
    }

    var canUndo: Bool {
        return audioEngine.tracks.contains { $0.canUndo() }
    }

    func toggleMonitoring() {
        audioEngine.toggleMonitoring()
        isMonitoring = audioEngine.isMonitoring
    }

    func toggleMetronome() {
        audioEngine.toggleMetronome()
        isMetronomeOn = audioEngine.metronome.isPlaying
    }

    func setBPM(_ newBPM: Double) {
        bpm = newBPM
        audioEngine.setBPM(newBPM)
    }

    func setTrackVolume(_ index: Int, volume: Float) {
        trackVolumes[index] = volume
        audioEngine.setTrackVolume(index, volume: volume)
    }

    func toggleTrackMute(_ index: Int) {
        trackMuted[index].toggle()
        audioEngine.setTrackMute(index, muted: trackMuted[index])
    }

    func setReverbMix(_ mix: Float) {
        reverbMix = mix
        audioEngine.setReverbMix(mix)
    }

    func setDelayMix(_ mix: Float) {
        delayMix = mix
        audioEngine.setDelayMix(mix)
    }

    @discardableResult
    func exportMix() -> URL? {
        return audioEngine.exportMix()
    }

    func saveProject(named name: String) {
        audioEngine.saveProject(named: name)
        refreshProjects()
    }

    func loadProject(named name: String) {
        audioEngine.loadProject(named: name)
        syncFromEngine()
    }

    func deleteProject(named name: String) {
        audioEngine.deleteProject(named: name)
        refreshProjects()
    }

    func refreshProjects() {
        savedProjects = audioEngine.listProjects()
    }

    var anyTrackHasContent: Bool {
        return audioEngine.tracks.contains { $0.hasContent }
    }

    var loopDuration: TimeInterval {
        guard audioEngine.loopLength > 0 else { return 0 }
        return TimeInterval(audioEngine.loopLength) / audioEngine.format.sampleRate
    }

    private func syncFromEngine() {
        guard !isUpdatingFromEngine else { return }
        isUpdatingFromEngine = true

        for (i, track) in audioEngine.tracks.enumerated() {
            if i < trackStates.count {
                trackStates[i] = track.state
            }
            if i < trackVolumes.count {
                trackVolumes[i] = track.volume
            }
            if i < trackMuted.count {
                trackMuted[i] = track.isMuted
            }
            if i < trackDurations.count {
                trackDurations[i] = track.duration
            }
        }

        isMonitoring = audioEngine.isMonitoring
        isMetronomeOn = audioEngine.metronome.isPlaying
        bpm = audioEngine.metronome.bpm

        isUpdatingFromEngine = false
    }
}
