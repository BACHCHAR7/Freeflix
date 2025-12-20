import Foundation
import SwiftUI
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = true
    @Published var error: String?
    @Published var selectedCategory: Category?
    
    var displayedCategories: [Category] {
        if let selected = selectedCategory {
            return categories.filter { $0.id == selected.id }
        }
        return categories
    }
    
    var featuredVideo: (video: Video, category: String, genre: String)? {
        for category in categories {
            for genre in category.genres {
                if let video = genre.videos.first {
                    return (video, category.name, genre.name)
                }
            }
        }
        return nil
    }
    
    func loadLibrary() async {
        isLoading = true
        error = nil
        
        do {
            categories = try await APIService.shared.fetchCategories()
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = "Impossible de charger la bibliotheque"
        }
        
        isLoading = false
    }
    
    func selectCategory(_ category: Category?) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if selectedCategory?.id == category?.id {
                selectedCategory = nil
            } else {
                selectedCategory = category
            }
        }
    }
}

