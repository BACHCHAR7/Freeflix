import SwiftUI

struct VideoPlayerView: View {
    let video: Video
    let onDismiss: () -> Void
    
    var body: some View {
        if let url = APIService.shared.streamURL(for: video) {
            FreeFlixPlayerView(url: url, onDismiss: onDismiss)
        } else {
            Color.black
                .onAppear { onDismiss() }
        }
    }
}
