import SwiftUI

extension Color {
    static let appBackground = Color(red: 0.05, green: 0.05, blue: 0.07)
    static let cardBackground = Color(red: 0.09, green: 0.09, blue: 0.12)
    static let controlBackground = Color(red: 0.13, green: 0.13, blue: 0.17)
    static let controlBorder = Color(red: 0.20, green: 0.20, blue: 0.25)
    static let accentGreen = Color(red: 0.11, green: 0.62, blue: 0.46)
    static let accentRed = Color(red: 0.88, green: 0.29, blue: 0.29)
    static let accentAmber = Color(red: 0.94, green: 0.62, blue: 0.15)
    static let accentBlue = Color(red: 0.22, green: 0.54, blue: 0.87)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.45)
    static let textDim = Color(white: 0.30)
}

func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

struct ContentView: View {
    @EnvironmentObject var viewModel: LoopViewModel
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                trackArea

                MasterControlsView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $viewModel.showingEffects) {
            EffectsSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingSaveDialog) {
            SaveProjectSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingLoadDialog) {
            LoadProjectSheet(viewModel: viewModel)
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 6) {
                Text("Loop")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text("6 tracks")
                    .font(.system(size: 11))
                    .foregroundColor(.textDim)
            }

            Spacer()

            HStack(spacing: 6) {
                HStack(spacing: 8) {
                    Button(action: { adjustBPM(-1) }) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textSecondary)
                            .frame(width: 22, height: 22)
                    }
                    Text("\(Int(viewModel.bpm))")
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(.textPrimary)
                        .frame(minWidth: 30)
                    Button(action: { adjustBPM(1) }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textSecondary)
                            .frame(width: 22, height: 22)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.controlBackground)
                .cornerRadius(10)

                toggleButton(
                    label: "Metro",
                    isOn: viewModel.isMetronomeOn,
                    onColor: .accentGreen
                ) {
                    haptic(.light)
                    viewModel.toggleMetronome()
                }

                toggleButton(
                    label: "Monitor",
                    isOn: viewModel.isMonitoring,
                    onColor: .accentBlue
                ) {
                    haptic(.light)
                    viewModel.toggleMonitoring()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private func toggleButton(label: String, isOn: Bool, onColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isOn ? onColor : .textDim)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.controlBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOn ? onColor.opacity(0.6) : Color.controlBorder, lineWidth: 1)
                )
        }
    }

    private func adjustBPM(_ delta: Double) {
        haptic(.light)
        viewModel.setBPM(max(40, min(300, viewModel.bpm + delta)))
    }

    private var trackArea: some View {
        Group {
            if verticalSizeClass == .compact {
                HStack(spacing: 8) {
                    VStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { i in
                            TrackRowView(index: i)
                                .environmentObject(viewModel)
                        }
                    }
                    VStack(spacing: 5) {
                        ForEach(3..<6, id: \.self) { i in
                            TrackRowView(index: i)
                                .environmentObject(viewModel)
                        }
                    }
                }
                .padding(.horizontal, 12)
            } else {
                ScrollView {
                    VStack(spacing: 5) {
                        ForEach(0..<6, id: \.self) { i in
                            TrackRowView(index: i)
                                .environmentObject(viewModel)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
    }
}

struct EffectsSheet: View {
    @ObservedObject var viewModel: LoopViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reverb")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        HStack {
                            Slider(value: $viewModel.reverbMix, in: 0...100, onEditingChanged: { _ in
                                viewModel.setReverbMix(viewModel.reverbMix)
                            })
                            .tint(.accentGreen)
                            Text("\(Int(viewModel.reverbMix))%")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.textSecondary)
                                .frame(width: 44, alignment: .trailing)
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(14)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Delay")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        HStack {
                            Slider(value: $viewModel.delayMix, in: 0...100, onEditingChanged: { _ in
                                viewModel.setDelayMix(viewModel.delayMix)
                            })
                            .tint(.accentAmber)
                            Text("\(Int(viewModel.delayMix))%")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.textSecondary)
                                .frame(width: 44, alignment: .trailing)
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(14)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Effects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.accentGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SaveProjectSheet: View {
    @ObservedObject var viewModel: LoopViewModel
    @Environment(\.dismiss) var dismiss
    @State private var projectName: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    TextField("Project name", text: $projectName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button(action: {
                        let name = projectName.isEmpty ? "Project \(Date().formatted(.dateTime.month().day().hour().minute()))" : projectName
                        viewModel.saveProject(named: name)
                        dismiss()
                    }) {
                        Text("Save")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentGreen)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 32)
            }
            .navigationTitle("Save Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct LoadProjectSheet: View {
    @ObservedObject var viewModel: LoopViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if viewModel.savedProjects.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.textDim)
                        Text("No saved projects")
                            .foregroundColor(.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.savedProjects, id: \.self) { name in
                                HStack {
                                    Button(action: {
                                        viewModel.loadProject(named: name)
                                        dismiss()
                                    }) {
                                        HStack {
                                            Image(systemName: "music.note")
                                                .foregroundColor(.accentGreen)
                                            Text(name)
                                                .foregroundColor(.textPrimary)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.cardBackground)
                                        .cornerRadius(12)
                                    }

                                    Button(action: {
                                        viewModel.deleteProject(named: name)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.accentRed)
                                            .padding()
                                            .background(Color.cardBackground)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Load Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.refreshProjects()
        }
    }
}
