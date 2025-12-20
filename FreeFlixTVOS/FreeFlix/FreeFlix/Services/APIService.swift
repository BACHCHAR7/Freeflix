import Foundation
import SwiftUI

final class APIService {
    static let shared = APIService()
    
    private let decoder: JSONDecoder
    
    private init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    private var baseURL: String {
        let stored = UserDefaults.standard.string(forKey: "serverURL") ?? "192.168.1.159:3001"
        return "http://\(stored)"
    }
    
    func fetchCategories() async throws -> [Category] {
        guard let url = URL(string: "\(baseURL)/api/categories") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        return try decoder.decode([Category].self, from: data)
    }
    
    func thumbnailURL(for video: Video) -> URL? {
        let encodedPath = encodePathForURL(video.path)
        return URL(string: "\(baseURL)/api/thumbnail/\(encodedPath)")
    }
    
    func streamURL(for video: Video) -> URL? {
        let encodedPath = encodePathForURL(video.path)
        let urlString = "\(baseURL)/api/hls/\(encodedPath)/master.m3u8"
        print("FreeFlix: HLS URL = \(urlString)")
        return URL(string: urlString)
    }
    
    func directStreamURL(for video: Video) -> URL? {
        let encodedPath = encodePathForURL(video.path)
        return URL(string: "\(baseURL)/api/stream/\(encodedPath)")
    }
    
    private func encodePathForURL(_ path: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "+")
        
        let encoded = path.addingPercentEncoding(withAllowedCharacters: allowed) ?? path
        return encoded
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case requestFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .requestFailed:
            return "Erreur de connexion au serveur"
        case .decodingFailed:
            return "Erreur de lecture des donnees"
        }
    }
}
