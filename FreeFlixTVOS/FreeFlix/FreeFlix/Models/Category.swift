import Foundation

struct Category: Codable, Identifiable, Hashable {
    let name: String
    let path: String
    let genres: [Genre]
    
    var id: String { path }
    
    var totalVideos: Int {
        genres.reduce(0) { $0 + $1.videos.count }
    }
}

