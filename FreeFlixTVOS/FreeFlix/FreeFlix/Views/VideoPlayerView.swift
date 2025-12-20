import SwiftUI

struct VideoPlayerView: View {
    let video: Video
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            
            if let url = APIService.shared.streamURL(for: video) {
                FreeFlixPlayerView(url: url, onDismiss: onDismiss)
            } else {
                Color.black
                    .onAppear { onDismiss() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }
}
