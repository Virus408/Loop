# Loop - iOS Loop Station

A real-time audio looping app for iPhone, inspired by the Boss RC-505 loop station. Record, loop, and overdub audio across 6 independent tracks with professional-grade low latency using AVAudioEngine.

## Features

- **6 independent tracks** - Record, loop, and layer audio on each track
- **Overdubbing** - Add new layers on top of existing recordings while they play
- **Auto loop-length sync** - First track recorded sets the loop length; subsequent tracks auto-align
- **Undo/Redo** - Revert the last overdub layer on any track
- **Real-time monitoring** - Hear your microphone input through headphones while recording
- **Simple metronome** - Adjustable BPM click track for timing reference
- **Audio effects** - Master reverb and delay with adjustable wet/dry mix
- **Save/Load projects** - Store and recall complete loop projects
- **Export** - Render your mix to an M4A audio file and share it
- **Dark stage theme** - High-contrast UI designed for stage and outdoor use
- **Portrait + Landscape** - Adaptive layout for any orientation
- **Haptic feedback** - Tactile response on all button presses
- **Large touch targets** - Optimized for finger operation on iPhone

## Requirements

- iOS 16.0+
- iPhone (optimized for one-handed finger operation)
- Microphone access
- Headphones recommended (to avoid feedback during monitoring)

## Build Instructions

You need a macOS environment to build this app. Three options:

### Option A: Build on a Mac with Xcode

```bash
# 1. Install XcodeGen
brew install xcodegen

# 2. Clone this repository
git clone <your-repo-url> Loop
cd Loop

# 3. Generate the Xcode project
xcodegen generate

# 4. Open in Xcode
open Loop.xcodeproj

# 5. In Xcode:
#    - Select your iPhone as the build target
#    - Select your signing team (Signing & Capabilities tab)
#    - Press Cmd+R to build and run
```

### Option B: Build via command line on a Mac

```bash
# 1. Install XcodeGen
brew install xcodegen

# 2. Generate and build
cd Loop
xcodegen generate
xcodebuild build \
  -project Loop.xcodeproj \
  -scheme Loop \
  -destination 'platform=iOS,name=YouriPhoneName' \
  -configuration Debug

# Or for a specific device:
xcodebuild build \
  -project Loop.xcodeproj \
  -scheme Loop \
  -destination 'id=YOUR_DEVICE_UDID' \
  -configuration Debug
```

### Option C: Build via GitHub Actions (no Mac needed)

1. Push this repository to GitHub
2. GitHub Actions will automatically build on every push
3. Download the `Loop-app` artifact from the Actions tab
4. The artifact contains the unsigned `.app` bundle
5. Use a signing service (e.g., AltStore, Sideloadly) to install on your iPhone

### Option D: Cloud Mac

1. Rent a cloud Mac (MacinCloud, MacStadium, etc.)
2. Follow Option A or B on the remote Mac

## Installing on Your iPhone

### With Apple Developer Account ($99/year)
1. Open the project in Xcode
2. Go to Signing & Capabilities
3. Select your development team
4. Connect your iPhone via USB
5. Build and run (Cmd+R)

### With Free Apple ID
1. Open the project in Xcode
2. Go to Signing & Capabilities
3. Select your personal team (free Apple ID)
4. Build and run
5. On your iPhone: Settings > General > VPN & Device Management > trust your developer certificate
6. Note: apps expire after 7 days and need to be rebuilt

## Usage Guide

### Basic Recording
1. Tap any track's large button to start recording
2. Tap again to stop recording - the track enters loop playback
3. The first track recorded sets the loop length for all subsequent tracks

### Overdubbing
1. While a track is playing (green), tap its button to start overdubbing
2. Your new audio is layered on top of the existing loop
3. Tap again to stop overdubbing - the layer is mixed in permanently

### Track Controls
- **Volume slider** - Adjust each track's volume independently
- **M (mute)** - Silence a track without clearing it
- **Trash icon** - Clear a track's content entirely

### Master Controls
- **Start All** - Start all tracks with content simultaneously
- **Stop All** - Stop all tracks (content is preserved)
- **Undo** - Revert the last overdub on any track
- **FX** - Open reverb and delay effect controls
- **Save** - Save the current project
- **Load** - Load a previously saved project
- **Export** - Render the mix to an M4A file and share

### Top Bar
- **BPM -/+** - Adjust metronome tempo
- **Metro** - Toggle metronome on/off
- **Monitor** - Toggle real-time mic monitoring (use with headphones)

### Track States
| State | Color | Action on Tap |
|-------|-------|---------------|
| Empty | Gray | Start recording |
| Recording | Red (pulsing) | Stop recording, start looping |
| Playing | Green | Start overdubbing |
| Overdubbing | Amber | Stop overdubbing |
| Stopped | Dim green | Resume playback |

## Project Structure

```
Loop/
├── project.yml                    # XcodeGen project configuration
├── README.md
├── .github/workflows/build.yml    # GitHub Actions CI build
├── .gitignore
└── Loop/                          # App source code
    ├── LoopApp.swift              # App entry point
    ├── Info.plist                 # Generated by XcodeGen
    ├── Assets.xcassets/           # App icon and colors
    ├── Models/
    │   └── TrackState.swift       # Track state enum and properties
    ├── Audio/
    │   ├── AudioEngine.swift      # Core audio engine (AVAudioEngine wrapper)
    │   ├── LoopTrack.swift        # Per-track recording/looping/overdub logic
    │   └── Metronome.swift        # Simple BPM metronome
    ├── ViewModels/
    │   └── LoopViewModel.swift    # Main view model connecting engine to UI
    └── Views/
        ├── ContentView.swift      # Main view, top bar, sheets
        ├── TrackRowView.swift     # Individual track card UI
        └── MasterControlsView.swift  # Bottom master control bar
```

## Technical Details

- **Audio engine**: AVAudioEngine with 6 AVAudioPlayerNodes routed through a master mixer
- **Signal chain**: Tracks + Monitor + Metronome -> MasterMixer -> Reverb -> Delay -> Output
- **Audio format**: 44.1 kHz, mono, Float32 (low latency)
- **Loop mechanism**: AVAudioPlayerNode.scheduleBuffer with .loops option
- **Overdub**: Real-time mic capture mixed into existing PCM buffer at correct loop position
- **Buffer I/O**: 5ms preferred IO buffer duration for minimal latency
- **Session**: .playAndRecord with .defaultToSpeaker and .allowBluetooth

## Troubleshooting

**No sound when recording**
- Check that headphones are connected (monitoring through speakers causes feedback)
- Verify microphone permission in Settings > Privacy > Microphone

**Audio latency**
- Use wired headphones instead of Bluetooth for lowest latency
- Close other audio apps running in the background

**Build fails**
- Ensure Xcode 15+ is installed
- Run `xcodegen generate` before opening the project
- Clean build folder: Cmd+Shift+K in Xcode

**App crashes on launch**
- Check that the microphone permission is granted
- Ensure iOS 16.0 or later

## License

Personal project. All rights reserved.
