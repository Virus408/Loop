import SwiftUI

enum TrackState: Int, CaseIterable {
    case empty = 0
    case recording = 1
    case playing = 2
    case overdubbing = 3
    case stopped = 4

    var label: String {
        switch self {
        case .empty: return "Tap to Record"
        case .recording: return "Recording"
        case .playing: return "Playing"
        case .overdubbing: return "Overdubbing"
        case .stopped: return "Stopped"
        }
    }

    var shortLabel: String {
        switch self {
        case .empty: return "REC"
        case .recording: return "STOP"
        case .playing: return "ODUB"
        case .overdubbing: return "STOP"
        case .stopped: return "PLAY"
        }
    }

    var color: Color {
        switch self {
        case .empty:
            return Color(red: 0.25, green: 0.25, blue: 0.30)
        case .recording:
            return Color(red: 0.88, green: 0.29, blue: 0.29)
        case .playing:
            return Color(red: 0.11, green: 0.62, blue: 0.46)
        case .overdubbing:
            return Color(red: 0.94, green: 0.62, blue: 0.15)
        case .stopped:
            return Color(red: 0.06, green: 0.35, blue: 0.26)
        }
    }

    var hasContent: Bool {
        switch self {
        case .playing, .overdubbing, .stopped: return true
        default: return false
        }
    }
}
