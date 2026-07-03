import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct MasterControlsView: View {
    @ObservedObject var viewModel: LoopViewModel
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var exportFailed = false
    @State private var pulseRec = false

    private var isRecording: Bool {
        viewModel.trackStates.contains { $0 == .recording || $0 == .overdubbing }
    }

    var body: some View {
        VStack(spacing: 8) {
            if isRecording {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.accentRed)
                        .frame(width: 8, height: 8)
                        .opacity(pulseRec ? 0.3 : 1.0)
                    Text("REC")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentRed)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        pulseRec = true
                    }
                }
                .padding(.bottom, 2)
            }

            HStack(spacing: 8) {
                Button(action: {
                    haptic(.heavy)
                    viewModel.startAll()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Start All")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentGreen)
                    .cornerRadius(14)
                }
                .buttonStyle(MasterButtonStyle())

                Button(action: {
                    haptic(.heavy)
                    viewModel.stopAll()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Stop All")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.accentRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.16, green: 0.08, blue: 0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.accentRed, lineWidth: 1.5)
                    )
                    .cornerRadius(14)
                }
                .buttonStyle(MasterButtonStyle())
            }

            HStack(spacing: 6) {
                masterButton(label: "Undo", icon: "arrow.uturn.backward", enabled: viewModel.canUndo) {
                    haptic(.medium)
                    viewModel.undoLast()
                }

                masterButton(label: "FX", icon: "slider.horizontal.3", enabled: true) {
                    viewModel.showingEffects = true
                }

                masterButton(label: "Save", icon: "tray.and.arrow.down", enabled: viewModel.anyTrackHasContent) {
                    viewModel.showingSaveDialog = true
                }

                masterButton(label: "Load", icon: "tray.and.arrow.up", enabled: !viewModel.savedProjects.isEmpty) {
                    viewModel.showingLoadDialog = true
                }

                masterButton(label: "Export", icon: "square.and.arrow.up", enabled: viewModel.anyTrackHasContent) {
                    if let url = viewModel.exportMix() {
                        shareURL = url
                        showingShareSheet = true
                    } else {
                        exportFailed = true
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Export Failed", isPresented: $exportFailed) {
            Button("OK") { }
        } message: {
            Text("Unable to export. Make sure at least one track has recorded content.")
        }
    }

    private func masterButton(label: String, icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(enabled ? .textPrimary : .textDim)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.controlBackground)
            .cornerRadius(12)
        }
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.4)
        .buttonStyle(MasterButtonStyle())
    }
}

struct MasterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
