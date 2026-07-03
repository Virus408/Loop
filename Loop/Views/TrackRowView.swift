import SwiftUI

struct TrackRowView: View {
    let index: Int
    @EnvironmentObject var viewModel: LoopViewModel
    @State private var pulse = false

    private var state: TrackState {
        viewModel.trackStates[index]
    }

    private var stateColor: Color {
        switch state {
        case .empty: return Color(red: 0.18, green: 0.18, blue: 0.22)
        case .recording: return .accentRed
        case .playing: return .accentGreen
        case .overdubbing: return .accentAmber
        case .stopped: return Color(red: 0.04, green: 0.30, blue: 0.22)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("\(index + 1)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(state == .empty ? .textDim : stateColor)
                    .frame(width: 22)

                Button(action: {
                    haptic(.medium)
                    viewModel.toggleTrack(index)
                }) {
                    HStack {
                        if state == .recording {
                            Circle()
                                .fill(Color.accentRed)
                                .frame(width: 8, height: 8)
                                .opacity(pulse ? 0.2 : 1.0)
                        }
                        Text(state.label)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(state == .empty ? .textDim : stateColor)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(stateColor.opacity(state == .empty ? 0.3 : 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(stateColor.opacity(state == .empty ? 0.4 : 0.8), lineWidth: 1.5)
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(TrackButtonStyle())

                Button(action: {
                    haptic(.light)
                    viewModel.clearTrack(index)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.textDim)
                        .frame(width: 34, height: 34)
                        .background(Color.controlBackground)
                        .cornerRadius(10)
                }
                .disabled(state == .empty)
                .opacity(state == .empty ? 0.3 : 1.0)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 6)

            HStack(spacing: 8) {
                Image(systemName: viewModel.trackMuted[index] ? "speaker.slash.fill" : "speaker.fill")
                    .font(.system(size: 11))
                    .foregroundColor(viewModel.trackMuted[index] ? .accentRed : .textDim)
                    .frame(width: 20)
                    .onTapGesture {
                        haptic(.light)
                        viewModel.toggleTrackMute(index)
                    }

                Slider(value: Binding(
                    get: { Double(viewModel.trackVolumes[index]) },
                    set: { viewModel.setTrackVolume(index, volume: Float($0)) }
                ), in: 0...1)
                .tint(state == .empty ? .textDim : .accentGreen)

                Text("\(Int(viewModel.trackVolumes[index] * 100))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.textDim)
                    .frame(width: 28, alignment: .trailing)

                if viewModel.trackDurations[index] > 0 {
                    Text(formatDuration(viewModel.trackDurations[index]))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.textDim)
                        .frame(width: 36, alignment: .trailing)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
        }
        .background(Color.cardBackground)
        .cornerRadius(14)
        .onAppear {
            if state == .recording {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
        .onChange(of: state) { newState in
            if newState == .recording {
                pulse = false
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            } else {
                pulse = false
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds >= 60 {
            return "\(seconds / 60):\(String(seconds % 60, paddingToLeft: 2, character: "0"))"
        } else {
            return "\(seconds)s"
        }
    }
}

struct TrackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension String {
    func paddingToLeft(length: Int, character: Character) -> String {
        if self.count >= length { return self }
        return String(repeatElement(character, count: length - self.count)) + self
    }
}
