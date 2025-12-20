import Foundation

struct Video: Codable, Identifiable, Hashable {
    let name: String
    let filename: String
    let path: String
    let size: Int64
    let modified: Date
    
    var id: String { path }
    
    var formattedSize: String {
        let gb = Double(size) / (1024 * 1024 * 1024)
        if gb >= 1 {
            return String(format: "%.1f Go", gb)
        }
        let mb = Double(size) / (1024 * 1024)
        return String(format: "%.0f Mo", mb)
    }
    
    var fileExtension: String {
        (filename as NSString).pathExtension.uppercased()
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: modified)
    }
}

