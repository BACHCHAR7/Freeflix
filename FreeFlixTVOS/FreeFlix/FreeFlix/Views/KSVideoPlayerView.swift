import SwiftUI
import KSPlayer

struct FreeFlixPlayerView: View {
    let url: URL
    let onDismiss: () -> Void
    
    private let options: KSOptions
    
    init(url: URL, onDismiss: @escaping () -> Void) {
        self.url = url
        self.onDismiss = onDismiss
        
        KSOptions.secondPlayerType = KSMEPlayer.self
        KSOptions.isAutoPlay = true
        KSOptions.isLoopPlay = false
        KSOptions.logLevel = .warning
        KSOptions.hardwareDecode = true
        KSOptions.preferredForwardBufferDuration = 8.0
        KSOptions.maxBufferDuration = 60.0
        
        let opts = KSOptions()
        opts.preferredForwardBufferDuration = 8.0
        opts.maxBufferDuration = 60.0
        opts.hardwareDecode = true
        opts.isSecondOpen = true
        opts.probesize = 5_000_000
        opts.maxAnalyzeDuration = 3_000_000
        opts.formatContextOptions["buffer_size"] = 32768 * 16
        opts.formatContextOptions["rw_timeout"] = 30_000_000
        self.options = opts
    }
    
    var body: some View {
        KSVideoPlayerView(url: url, options: options)
            .onDisappear {
                onDismiss()
            }
    }
}
