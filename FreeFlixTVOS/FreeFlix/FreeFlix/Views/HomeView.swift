import SwiftUI

struct SelectedVideoInfo: Identifiable {
    let id = UUID()
    let video: Video
    let category: String
    let genre: String
}

struct PlayingVideo: Identifiable {
    let id = UUID()
    let video: Video
}

struct HomeView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var selectedVideo: SelectedVideoInfo?
    @State private var playingVideo: Video?
    
    var body: some View {
        ZStack {
            Color.ffBackground.ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error)
            } else if viewModel.categories.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .fullScreenCover(item: Binding(
            get: { playingVideo.map { PlayingVideo(video: $0) } },
            set: { playingVideo = $0?.video }
        )) { playing in
            VideoPlayerView(video: playing.video) {
                playingVideo = nil
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $selectedVideo) { selected in
            VideoDetailView(
                video: selected.video,
                category: selected.category,
                genre: selected.genre,
                onPlay: {
                    let video = selected.video
                    selectedVideo = nil
                    // Increased delay to ensure the detail view is fully dismissed
                    // and the system is ready for the fullScreenCover transition.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        playingVideo = video
                    }
                },
                onDismiss: { selectedVideo = nil }
            )
            .background(ClearBackgroundView())
        }
        .animation(.easeInOut(duration: 0.3), value: playingVideo != nil)
        .task { await viewModel.loadLibrary() }
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(2)
                .tint(.ffAccent)
            
            Text("Chargement")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.ffSecondary)
                .tracking(2)
                .textCase(.uppercase)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.ffAccent)
            
            Text(message)
                .font(.system(size: 28))
                .foregroundColor(.ffSecondary)
            
            Button("Reessayer") {
                Task { await viewModel.loadLibrary() }
            }
            .buttonStyle(RetryButtonStyle())
            .padding(.top, 20)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "film")
                .font(.system(size: 100))
                .foregroundColor(.ffMuted)
            
            Text("Aucune video")
                .font(.system(size: 36, weight: .semibold))
            
            Text("Ajoutez des videos dans Videos/Categories/[Films|Series]/[Genre]/")
                .font(.system(size: 22))
                .foregroundColor(.ffSecondary)
        }
    }
    
    private var contentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    if let featured = viewModel.featuredVideo {
                        HeroView(
                            video: featured.video,
                            category: featured.category,
                            genre: featured.genre,
                            onPlay: { playingVideo = featured.video },
                            onInfo: { 
                                selectedVideo = SelectedVideoInfo(
                                    video: featured.video,
                                    category: featured.category,
                                    genre: featured.genre
                                )
                            }
                        )
                    }
                    
                    HeaderView(
                        categories: viewModel.categories,
                        selectedCategory: viewModel.selectedCategory,
                        onSelectCategory: { viewModel.selectCategory($0) }
                    )
                }
                
                VStack(spacing: 50) {
                    ForEach(viewModel.displayedCategories) { category in
                        VStack(alignment: .leading, spacing: 30) {
                            Text(category.name)
                                .font(.system(size: 34, weight: .bold))
                                .padding(.leading, 80)
                            
                            ForEach(category.genres) { genre in
                                CategoryRowView(
                                    genre: genre,
                                    categoryName: category.name
                                ) { video in
                                    selectedVideo = SelectedVideoInfo(
                                        video: video,
                                        category: category.name,
                                        genre: genre.name
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.top, -100)
                .padding(.bottom, 100)
            }
        }
    }
}

struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct RetryButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 24, weight: .semibold))
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(isFocused ? Color.ffAccent : Color.white.opacity(0.2))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    HomeView()
}
