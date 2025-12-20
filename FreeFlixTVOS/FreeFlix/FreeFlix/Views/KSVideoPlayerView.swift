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
        KSOptions.preferredForwardBufferDuration = 15.0
        KSOptions.maxBufferDuration = 120.0
        
        let opts = KSOptions()
        opts.preferredForwardBufferDuration = 15.0
        opts.maxBufferDuration = 120.0
        opts.hardwareDecode = true
        opts.isSecondOpen = true
        opts.probesize = 10_000_000
        opts.maxAnalyzeDuration = 5_000_000
        opts.formatContextOptions["buffer_size"] = 1024 * 1024
        opts.formatContextOptions["rw_timeout"] = 60_000_000
        opts.formatContextOptions["reconnect"] = 1
        opts.formatContextOptions["reconnect_streamed"] = 1
        opts.formatContextOptions["reconnect_delay_max"] = 5
        self.options = opts
    }
    
    var body: some View {
        KSVideoPlayerView(url: url, options: options)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
            .background(Color.black)
            .onDisappear {
                onDismiss()
            }
    }
}
