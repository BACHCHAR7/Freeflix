import SwiftUI

struct HeroView: View {
    let video: Video
    let category: String
    let genre: String
    let onPlay: () -> Void
    let onInfo: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geo in
                AsyncImage(url: APIService.shared.thumbnailURL(for: video)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    default:
                        Rectangle()
                            .fill(Color.ffCard)
                    }
                }
            }
            .frame(height: 700)
            
            LinearGradient(
                colors: [.clear, .ffBackground.opacity(0.5), .ffBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            
            LinearGradient(
                colors: [.ffBackground, .ffBackground.opacity(0.8), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 800)
            
            VStack(alignment: .leading, spacing: 20) {
                Text(category.uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .tracking(2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.ffAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(video.name)
                    .font(.system(size: 64, weight: .bold))
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.8), radius: 10)
                
                Text(genre)
                    .font(.system(size: 28))
                    .foregroundColor(.ffSecondary)
                
                HStack(spacing: 20) {
                    Button(action: onPlay) {
                        HStack(spacing: 14) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 24))
                            Text("Lecture")
                                .font(.system(size: 24, weight: .semibold))
                        }
                    }
                    .buttonStyle(HeroPlayButtonStyle())
                    
                    Button(action: onInfo) {
                        HStack(spacing: 14) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 24))
                            Text("Infos")
                                .font(.system(size: 24, weight: .semibold))
                        }
                    }
                    .buttonStyle(HeroSecondaryButtonStyle())
                }
                .padding(.top, 20)
            }
            .padding(.leading, 80)
            .padding(.bottom, 180)
        }
    }
}

struct HeroPlayButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 40)
            .padding(.vertical, 18)
            .background(isFocused ? Color.white : Color.white.opacity(0.95))
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.ffAccent, lineWidth: isFocused ? 4 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.05 : 1.0))
            .shadow(
                color: isFocused ? Color.ffAccent.opacity(0.6) : .clear,
                radius: isFocused ? 20 : 0
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct HeroSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 40)
            .padding(.vertical, 18)
            .background(isFocused ? Color.white.opacity(0.3) : Color.white.opacity(0.2))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.ffAccent, lineWidth: isFocused ? 4 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.05 : 1.0))
            .shadow(
                color: isFocused ? Color.ffAccent.opacity(0.6) : .clear,
                radius: isFocused ? 20 : 0
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

