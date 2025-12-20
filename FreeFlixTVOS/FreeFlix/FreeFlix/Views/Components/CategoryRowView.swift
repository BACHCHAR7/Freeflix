import SwiftUI

struct CategoryRowView: View {
    let genre: Genre
    let categoryName: String
    let onVideoSelect: (Video) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(genre.name)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.ffSecondary)
                .padding(.leading, 80)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    ForEach(genre.videos) { video in
                        Button {
                            onVideoSelect(video)
                        } label: {
                            VideoCardContent(video: video)
                        }
                        .buttonStyle(VideoCardButtonStyle())
                    }
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 30)
            }
        }
    }
}

struct VideoCardContent: View {
    let video: Video
    @Environment(\.isFocused) var isFocused
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                AsyncImage(url: APIService.shared.thumbnailURL(for: video)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.ffCard)
                            .overlay { ProgressView().tint(.white) }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color.ffCard, Color.ffBackground],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.ffMuted)
                            }
                    @unknown default:
                        Rectangle().fill(Color.ffCard)
                    }
                }
                .frame(width: 400, height: 225)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if isFocused {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.4))
                        .frame(width: 400, height: 225)
                    
                    Circle()
                        .fill(.white.opacity(0.95))
                        .frame(width: 70, height: 70)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.black)
                                .offset(x: 2)
                        }
                        .shadow(color: .black.opacity(0.3), radius: 10)
                }
            }
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.ffAccent, lineWidth: 6)
                        .shadow(color: Color.ffAccent.opacity(0.5), radius: 15)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(video.name)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isFocused ? .white : .ffSecondary)
                    .lineLimit(1)
                
                Text(video.formattedSize)
                    .font(.system(size: 18))
                    .foregroundColor(.ffMuted)
            }
            .frame(width: 400, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}

struct VideoCardButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
