import Foundation

struct Genre: Codable, Identifiable, Hashable {
    let name: String
    let path: String
    let videos: [Video]
    
    var id: String { path }
}

