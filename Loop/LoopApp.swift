import SwiftUI

@main
struct LoopApp: App {
    @StateObject private var viewModel = LoopViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
