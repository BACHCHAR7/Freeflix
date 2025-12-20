import SwiftUI

struct VideoDetailView: View {
    let video: Video
    let category: String
    let genre: String
    let onPlay: () -> Void
    let onDismiss: () -> Void
    
    @FocusState private var focusedButton: DetailButton?
    
    enum DetailButton: Hashable {
        case play
        case close
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    AsyncImage(url: APIService.shared.thumbnailURL(for: video)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 500)
                                .clipped()
                        default:
                            Rectangle()
                                .fill(Color.ffCard)
                                .frame(height: 500)
                        }
                    }
                    
                    LinearGradient(
                        colors: [.clear, .ffSecondaryBg],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        Text(video.name)
                            .font(.system(size: 52, weight: .bold))
                            .shadow(color: .black.opacity(0.8), radius: 10)
                        
                        HStack(spacing: 20) {
                            Button(action: onPlay) {
                                HStack(spacing: 14) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 26))
                                    Text("Lecture")
                                        .font(.system(size: 26, weight: .semibold))
                                }
                            }
                            .buttonStyle(PlayButtonStyle())
                            .focused($focusedButton, equals: .play)
                            
                            Button(action: onDismiss) {
                                HStack(spacing: 14) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 24))
                                    Text("Fermer")
                                        .font(.system(size: 26, weight: .semibold))
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .focused($focusedButton, equals: .close)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 40)
                }
                
                HStack(alignment: .top, spacing: 60) {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 12) {
                            TagView(text: category, style: .accent)
                            TagView(text: genre, style: .secondary)
                            TagView(text: video.fileExtension, style: .muted)
                        }
                        
                        Text("Profitez de ce contenu en streaming haute qualite directement depuis votre bibliotheque personnelle.")
                            .font(.system(size: 24))
                            .foregroundColor(.ffSecondary)
                            .lineSpacing(6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        DetailRow(label: "Fichier", value: video.filename)
                        DetailRow(label: "Taille", value: video.formattedSize)
                        DetailRow(label: "Modifie le", value: video.formattedDate)
                    }
                    .frame(width: 400)
                }
                .padding(60)
            }
            .frame(width: 1400)
            .background(Color.ffSecondaryBg)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.6), radius: 50)
        }
        .onAppear {
            focusedButton = .play
        }
        .onExitCommand {
            onDismiss()
        }
    }
}

struct PlayButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 50)
            .padding(.vertical, 20)
            .background(isFocused ? Color.white : Color.white.opacity(0.95))
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
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

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 50)
            .padding(.vertical, 20)
            .background(isFocused ? Color.white.opacity(0.3) : Color.white.opacity(0.2))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
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

struct TagView: View {
    enum Style { case accent, secondary, muted }
    
    let text: String
    let style: Style
    
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 16, weight: .bold))
            .tracking(1)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var backgroundColor: Color {
        switch style {
        case .accent: return .ffAccent
        case .secondary: return .white.opacity(0.15)
        case .muted: return .white.opacity(0.1)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .accent: return .white
        case .secondary: return .white
        case .muted: return .ffSecondary
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 14, weight: .semibold))
                .tracking(2)
                .foregroundColor(.ffMuted)
            
            Text(value)
                .font(.system(size: 20))
                .foregroundColor(.ffSecondary)
                .lineLimit(2)
        }
    }
}
