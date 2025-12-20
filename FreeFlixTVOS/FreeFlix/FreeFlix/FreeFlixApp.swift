import SwiftUI

@main
struct FreeFlixApp: App {
    @State private var splashFinished = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if splashFinished {
                    ContentView()
                        .transition(.opacity)
                } else {
                    SplashView(isFinished: $splashFinished)
                }
            }
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.5), value: splashFinished)
        }
    }
}
